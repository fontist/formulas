#!/usr/bin/env ruby
# frozen_string_literal: true

# Renders fontist formula check results into multiple publishing surfaces.
#
# ARCHITECTURE
# ------------
# This is Layer 2 of the formula-health reporting pipeline:
#
#   Layer 1 (checkers):   validate_schema.rb, check_urls.rb, install_formulas.rb
#                         Each emits results/<name>.json using a unified schema.
#   Layer 2 (renderer):   THIS FILE. Reads results/*.json, writes rendered
#                         surfaces (markdown + aggregated JSON).
#   Layer 3 (publishers): workflow jobs that post PR comments, create issues,
#                         populate $GITHUB_STEP_SUMMARY, and upload artifacts.
#
# UNIFIED RESULTS SCHEMA (consumed by this script)
# -----------------------------------------------
#   {
#     "check":         "schema" | "urls" | "install",
#     "platform":      "all" | "linux" | "macos" | "windows",
#     "scope":         "full" | "rotation:1" | "rotation:2" | "changed:N",
#     "started_at":    ISO8601,
#     "completed_at":  ISO8601,
#     "summary": { "total": N, "passed": N, "failed": N, "warnings": N, "skipped": N },
#     "failures": [
#       {
#         "formula":     "noto_sans",                              # required
#         "formula_path":"Formulas/google/noto_sans.yml",          # required, repo-relative
#         "url":         "https://...",                            # optional (url check only)
#         "message":     "Not Found (404)",                        # required, human-readable
#         "severity":    "error" | "warning"                       # default "error"
#       }
#     ],
#     "warnings": [ ... same shape, severity: "warning" ... ]
#   }
#
# OUTPUTS
# -------
#   reports/pr-comment.md    PR comment body. Truncated to fit GitHub's 65,535
#                            char limit. Uses <details> for scannability.
#   reports/issue-body.md    Full issue body. No truncation. Includes all failures.
#   reports/step-summary.md  Compact content for $GITHUB_STEP_SUMMARY.
#   reports/health.json      Aggregated data for the docs dashboard (Phase 2).
#
# USAGE
# -----
#   ruby render_report.rb \
#     --input-dir results/ \
#     --output-dir reports/ \
#     --run-url https://github.com/fontist/formulas/actions/runs/123 \
#     --commit-sha abc123def \
#     [--pr-number 456] \
#     [--max-pr-comment-chars 60000]

require "json"
require "optparse"
require "time"
require "fileutils"

class RenderReport
  GITHUB_COMMENT_LIMIT = 65_535
  DEFAULT_PR_BUDGET = 60_000 # safety margin under GitHub's hard limit
  REPO_BASE = "https://github.com/fontist/formulas"

  # One checker's run result, normalised from JSON.
  Result = Struct.new(
    :check, :platform, :scope, :started_at, :completed_at,
    :summary, :failures, :warnings, :source_file,
    keyword_init: true
  ) do
    def failed?
      summary[:failed].to_i.positive? || failures.any?
    end

    def label
      case check
      when "schema"  then "Schema"
      when "urls"    then "URLs"
      when "install" then "Install (#{platform})"
      else check.to_s
      end
    end
  end

  def initialize(_args)
    OptionParser.new do |opts|
      opts.banner = "Usage: ruby render_report.rb [options]"

      opts.on("--input-dir DIR", "Directory containing results/*.json") do |d|
        @input_dir = d
      end
      opts.on("--output-dir DIR", "Directory to write reports/") do |d|
        @output_dir = d
      end
      opts.on("--run-url URL", "Workflow run URL (for links)") { |u| @run_url = u }
      opts.on("--commit-sha SHA", "Git commit SHA (for source links)") { |s| @commit_sha = s }
      opts.on("--pr-number N", Integer, "PR number, if running on a PR") { |n| @pr_number = n }
      opts.on("--max-pr-comment-chars N", Integer, "Truncate PR comment to fit") do |n|
        @pr_budget = n
      end
    end.parse!

    @input_dir ||= "results"
    @output_dir ||= "reports"
    @run_url ||= ENV.fetch("GITHUB_RUN_URL", nil)
    @commit_sha ||= ENV.fetch("GITHUB_SHA", nil)
    @pr_number ||= ENV.fetch("PR_NUMBER", nil)
    @pr_budget ||= DEFAULT_PR_BUDGET
  end

  def call
    results = load_results
    FileUtils.mkdir_p(@output_dir)

    write("pr-comment.md", render_pr_comment(results))
    write("issue-body.md", render_issue_body(results))
    write("step-summary.md", render_step_summary(results))
    write("health.json", render_health_json(results))

    puts "Reports written to #{@output_dir}/"
    puts "  Loaded #{results.size} result file(s): #{results.map(&:label).join(', ')}"
  end

  private

  # ─────────────────────────────────────────────────────────────────────────
  # Loading
  # ─────────────────────────────────────────────────────────────────────────

  def load_results
    files = Dir.glob(File.join(@input_dir, "**/*.json")).sort
    files.map { |f| load_result(f) }.compact
  end

  def load_result(file)
    data = JSON.parse(File.read(file))
    Result.new(
      check: data["check"],
      platform: data["platform"] || "all",
      scope: data["scope"] || "full",
      started_at: data["started_at"],
      completed_at: data["completed_at"],
      summary: symbolise_summary(data["summary"] || {}),
      failures: data["failures"] || [],
      warnings: data["warnings"] || [],
      source_file: file,
    )
  rescue JSON::ParserError => e
    warn "WARN: Failed to parse #{file}: #{e.message}"
    nil
  rescue StandardError => e
    warn "WARN: Failed to load #{file}: #{e.message}"
    nil
  end

  def symbolise_summary(hash)
    keys = %i[total passed failed warnings skipped]
    keys.each_with_object({}) do |k, h|
      h[k] = hash[k.to_s].to_i if hash.key?(k.to_s)
    end
  end

  # ─────────────────────────────────────────────────────────────────────────
  # Aggregation
  # ─────────────────────────────────────────────────────────────────────────

  # Group failures by check label, e.g. "URLs" => [failure, ...]
  def failures_by_check(results)
    results.each_with_object({}) do |r, h|
      next if r.failures.empty?

      h[r.label] ||= []
      h[r.label].concat(r.failures)
    end
  end

  def total_failures(results)
    results.sum { |r| r.failures.size }
  end

  def failed_checks_count(results)
    results.count(&:failed?)
  end

  # ─────────────────────────────────────────────────────────────────────────
  # Surface: PR comment
  # ─────────────────────────────────────────────────────────────────────────

  def render_pr_comment(results)
    full = build_pr_comment(results)
    return full if full.size <= @pr_budget

    truncate_pr_comment(results, full)
  end

  def build_pr_comment(results)
    parts = []
    parts << pr_header(results)
    parts << summary_table(results)
    parts.concat(failure_sections(results, default_collapsed_threshold: 5))
    parts << pr_footer
    parts.compact.join("\n\n")
  end

  def pr_header(results)
    total = results.size
    failed = failed_checks_count(results)
    status_word = failed.zero? ? "PASS" : "FAIL"
    status_icon = failed.zero? ? "✅" : "❌"

    meta = []
    meta << "[workflow](#{@run_url})" if @run_url
    meta << "[full JSON](#{@run_url}#artifacts)" if @run_url

    header = "## #{status_icon} Fontist formula checks: **#{status_word}**\n"
    header += "> **#{failed} of #{total}** checks failed"
    header += " · " + meta.join(" · ") if meta.any?
    header
  end

  def summary_table(results)
    rows = results.map do |r|
      status = if r.summary[:failed].to_i.positive?
                 "❌ **#{r.summary[:failed]} failed**"
               elsif r.failures.any?
                 "❌ **#{r.failures.size} failed**"
               else
                 "✅ pass"
               end
      scope = format_scope(r)
      "| #{r.label} | #{scope} | #{status} |"
    end

    table = []
    table << "| Check | Scope | Result |"
    table << "|-------|-------|--------|"
    table.concat(rows)
    table.join("\n")
  end

  def format_scope(result)
    parts = []
    parts << result.scope
    total = result.summary[:total]
    parts << "#{total} item#{'s' if total.to_i != 1}" if total
    parts.join(" · ")
  end

  def failure_sections(results, default_collapsed_threshold:)
    sections = []
    failures_by_check(results).each do |label, failures|
      # Collapse if many failures; open if few.
      open = failures.size <= default_collapsed_threshold
      sections << render_failure_section(label, failures, open: open)
    end
    sections
  end

  def render_failure_section(label, failures, open:)
    body = render_failure_table(failures)
    open_attr = open ? " open" : ""
    noun = failures.size == 1 ? "failure" : "failures"
    summary = "<summary><b>#{label}</b> — #{failures.size} #{noun}</summary>"

    [
      "<details#{open_attr}>",
      summary,
      "",
      body,
      "</details>",
    ].join("\n")
  end

  def render_failure_table(failures)
    header = "| Formula | Detail |"
    separator = "|---------|--------|"

    rows = failures.map do |f|
      formula = format_formula_link(f)
      detail = format_failure_detail(f)
      "| #{formula} | #{detail} |"
    end

    [header, separator, *rows].join("\n")
  end

  def format_formula_link(failure)
    path = failure["formula_path"]
    formula = failure["formula"] || (path ? File.basename(path, ".yml") : "unknown")
    return "`#{formula}`" unless path && @commit_sha

    "[`#{formula}`](#{REPO_BASE}/blob/#{@commit_sha}/#{path})"
  end

  def format_failure_detail(failure)
    parts = []
    if failure["url"]
      url = failure["url"]
      safe_url = redact_url(url)
      parts << "[`#{safe_url}`](#{safe_url})"
    end
    parts << failure["message"].to_s if failure["message"]
    parts.join(" · ")
  end

  def redact_url(url)
    return url unless url.is_a?(String) && url.include?("?")

    base = url.split("?").first
    "#{base}?…(query redacted)"
  end

  def pr_footer
    footer = "_Generated by `render_report.rb` from `results/*.json` artifacts._"
    footer += "  \n_Opens or updates the issue when this is a scheduled run._" unless @pr_number
    footer
  end

  # Truncation: keep header + summary + as many failure rows as fit.
  # Drop rows from the longest section first, then add a truncation note.
  def truncate_pr_comment(results, full_body)
    truncation_note_len = 200
    target = @pr_budget - truncation_note_len
    return full_body if full_body.size <= target

    # Recompute failures per check, capped progressively.
    # Strategy: cap each section proportionally, retry until fits.
    (1..50).each do |attempt|
      cap = [10 + (10 * attempt), 200].min # gentle ramp
      capped = failures_by_check(results).transform_values { |fs| fs.first(cap) }

      body_parts = []
      body_parts << pr_header(results)
      body_parts << summary_table(results)
      body_parts.concat(capped_failure_sections(capped, results))
      body_parts << truncation_note(results, capped, total_failures(results))
      body_parts << pr_footer
      body = body_parts.compact.join("\n\n")

      return body if body.size <= @pr_budget
    end

    # Last resort: hard-truncate the body.
    full_body[0...@pr_budget - 200] + "\n\n> ⚠️ Truncated. See `health.json` artifact."
  end

  def capped_failure_sections(capped_failures, results)
    sections = []
    capped_failures.each do |label, failures|
      next if failures.empty?

      r = results.find { |x| x.label == label }
      open = failures.size <= 5
      sections << render_failure_section(label, failures, open: open)
    end
    sections
  end

  def truncation_note(_results, capped, total)
    shown = capped.values.sum(&:size)
    hidden = total - shown
    return "" if hidden <= 0

    artifact_link = @run_url ? "[workflow artifacts](#{@run_url}#artifacts)" : "workflow artifacts"
    "> ℹ️ Showing **#{shown} of #{total}** failures. " \
      "See `health.json` in #{artifact_link} for the full report."
  end

  # ─────────────────────────────────────────────────────────────────────────
  # Surface: Issue body (no truncation)
  # ─────────────────────────────────────────────────────────────────────────

  def render_issue_body(results)
    parts = []
    parts << issue_header(results)
    parts << summary_table(results)
    parts.concat(failure_sections(results, default_collapsed_threshold: 1_000_000))
    parts << issue_footer
    parts.compact.join("\n\n")
  end

  def issue_header(results)
    failed = failed_checks_count(results)
    timestamp = Time.now.utc.iso8601

    header = "## Formula Health Check Failed\n\n" \
              "The periodic formula health check detected failures.\n\n"
    header += "- **Workflow run:** #{@run_url}\n" if @run_url
    header += "- **Commit:** `#{@commit_sha}`\n" if @commit_sha
    header += "- **Generated at:** #{timestamp}\n"
    header += "- **Failed checks:** #{failed} of #{results.size}\n"
    header
  end

  def issue_footer
    "\n---\n_This issue was automatically created by the `formula-health` workflow. " \
      "It will be auto-closed when all health checks pass._"
  end

  # ─────────────────────────────────────────────────────────────────────────
  # Surface: Step summary (compact)
  # ─────────────────────────────────────────────────────────────────────────

  def render_step_summary(results)
    parts = []
    parts << step_summary_header(results)
    parts << summary_table(results)

    # Show top 3 failures per check only.
    failures_by_check(results).each do |label, failures|
      top = failures.first(3)
      extra = failures.size - top.size
      section_label = extra.positive? ? "#{label} (top #{top.size})" : label
      parts << render_failure_section(section_label, top, open: true)
      if extra.positive?
        parts << "_...and #{extra} more failure#{'s' if extra != 1}. " \
                "See issue/artifact for full list._"
      end
    end

    parts.compact.join("\n\n")
  end

  def step_summary_header(results)
    failed = failed_checks_count(results)
    icon = failed.zero? ? "✅" : "❌"
    "## #{icon} Formula check summary\n" \
      "**#{failed} of #{results.size}** checks failed."
  end

  # ─────────────────────────────────────────────────────────────────────────
  # Surface: health.json (for docs dashboard, Phase 2)
  # ─────────────────────────────────────────────────────────────────────────

  def render_health_json(results)
    data = {
      generated_at: Time.now.utc.iso8601,
      commit_sha: @commit_sha,
      run_url: @run_url,
      totals: {
        checks_run: results.size,
        checks_failed: failed_checks_count(results),
        total_failures: total_failures(results),
      },
      checks: results.map do |r|
        {
          check: r.check,
          platform: r.platform,
          scope: r.scope,
          label: r.label,
          started_at: r.started_at,
          completed_at: r.completed_at,
          summary: r.summary,
          failed: r.failed?,
          failure_count: r.failures.size,
          failures: r.failures,
        }
      end,
    }
    JSON.pretty_generate(data)
  end

  # ─────────────────────────────────────────────────────────────────────────
  # IO
  # ─────────────────────────────────────────────────────────────────────────

  def write(filename, content)
    path = File.join(@output_dir, filename)
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, content)
    puts "  Wrote #{filename} (#{content.size} bytes)"
  end
end

RenderReport.new(ARGV.dup).call
