#!/usr/bin/env ruby
# frozen_string_literal: true

# Tests for render_report.rb.
# Run with:  ruby test/test_render_report.rb
#
# Plain-Ruby style — no rspec — matches the repo's existing test/test_*.rb pattern.

require "json"
require "tmpdir"
require "fileutils"

$pass = 0
$fail = 0

def assert(label, actual, expected = nil)
  if expected.nil?
    if actual
      $pass += 1
    else
      $fail += 1
      warn "FAIL: #{label}: expected truthy, got #{actual.inspect}"
    end
  elsif actual == expected
    $pass += 1
  else
    $fail += 1
    warn "FAIL: #{label}"
    warn "  expected: #{expected.inspect}"
    warn "  actual:   #{actual.inspect}"
  end
end

def assert_includes(label, haystack, needle)
  if haystack.to_s.include?(needle)
    $pass += 1
  else
    $fail += 1
    warn "FAIL: #{label}"
    warn "  expected to include: #{needle.inspect}"
    warn "  in: #{haystack.to_s[0..500]}"
  end
end

def assert_not_includes(label, haystack, needle)
  if haystack.to_s.include?(needle)
    $fail += 1
    warn "FAIL: #{label}"
    warn "  expected NOT to include: #{needle.inspect}"
    warn "  in: #{haystack.to_s[0..500]}"
  else
    $pass += 1
  end
end

def assert_lt(label, actual, limit)
  if actual < limit
    $pass += 1
  else
    $fail += 1
    warn "FAIL: #{label}: expected < #{limit}, got #{actual}"
  end
end

SCRIPT = File.expand_path("../.github/scripts/render_report.rb", __dir__)

def run_renderer(input_dir, output_dir, opts = {})
  cmd = ["ruby", SCRIPT, "--input-dir", input_dir, "--output-dir", output_dir]
  cmd += ["--run-url", opts[:run_url]] if opts[:run_url]
  cmd += ["--commit-sha", opts[:commit_sha]] if opts[:commit_sha]
  cmd += ["--pr-number", opts[:pr_number].to_s] if opts[:pr_number]
  cmd += ["--max-pr-comment-chars", opts[:budget].to_s] if opts[:budget]
  system(*cmd, out: "/dev/null", err: "/dev/null")
  outputs = {}
  %w[pr-comment.md issue-body.md step-summary.md health.json].each do |f|
    path = File.join(output_dir, f)
    outputs[f] = File.exist?(path) ? File.read(path) : nil
  end
  outputs
end

def write_result(dir, name, data)
  FileUtils.mkdir_p(dir)
  File.write(File.join(dir, name), JSON.pretty_generate(data))
end

def sample_result(check:, platform: "all", scope: "full", failures: [], warnings: [])
  {
    "check" => check,
    "platform" => platform,
    "scope" => scope,
    "started_at" => "2026-06-18T10:00:00Z",
    "completed_at" => "2026-06-18T10:05:00Z",
    "summary" => {
      "total" => 100,
      "passed" => 100 - failures.size,
      "failed" => failures.size,
      "warnings" => warnings.size,
      "skipped" => 0,
    },
    "failures" => failures,
    "warnings" => warnings,
  }
end

def sample_failure(formula:, path: "Formulas/#{formula}.yml", url: nil, message: "Bad thing")
  f = { "formula" => formula, "formula_path" => path, "message" => message, "severity" => "error" }
  f["url"] = url if url
  f
end

# ────────────────────────────────────────────────────────────────────────────
# Test 1: all-passing
# ────────────────────────────────────────────────────────────────────────────
Dir.mktmpdir("ff-render-") do |input, _|
  output = File.join(input, "out")
  write_result(input, "schema.json",
               sample_result(check: "schema", failures: []))
  write_result(input, "urls.json",
               sample_result(check: "urls", failures: []))

  out = run_renderer(input, output, run_url: "https://example/run/1")
  assert("all-pass: pr-comment.md present", !out["pr-comment.md"].nil?)
  assert_includes("all-pass: shows PASS", out["pr-comment.md"], "PASS")
  assert_includes("all-pass: has ✅", out["pr-comment.md"], "✅")
  assert_not_includes("all-pass: no failure section", out["pr-comment.md"], "failures</summary>")
end

# ────────────────────────────────────────────────────────────────────────────
# Test 2: mixed pass/fail
# ────────────────────────────────────────────────────────────────────────────
Dir.mktmpdir("ff-render-") do |input, _|
  output = File.join(input, "out")
  write_result(input, "schema.json", sample_result(check: "schema", failures: []))
  write_result(input, "urls.json",
               sample_result(check: "urls",
                             failures: [
                               sample_failure(formula: "noto_sans",
                                              path: "Formulas/google/noto_sans.yml",
                                              url: "https://fonts.gstatic.com/x.woff2",
                                              message: "Not Found (404)"),
                             ]))

  out = run_renderer(input, output,
                     run_url: "https://example/run/2",
                     commit_sha: "abc123")
  pr = out["pr-comment.md"]
  assert_includes("mixed: shows FAIL", pr, "FAIL")
  assert_includes("mixed: shows broken formula name", pr, "noto_sans")
  assert_includes("mixed: shows URL", pr, "fonts.gstatic.com/x.woff2")
  assert_includes("mixed: shows error", pr, "Not Found (404)")
  assert_includes("mixed: source link uses commit sha", pr, "/blob/abc123/Formulas/google/noto_sans.yml")
  assert_includes("mixed: workflow link present", pr, "(https://example/run/2)")

  # health.json should be valid JSON with check data
  health = JSON.parse(out["health.json"])
  assert("mixed: health.json has 2 checks", health["checks"].size, 2)
  assert("mixed: health.json totals failures", health["totals"]["total_failures"], 1)
end

# ────────────────────────────────────────────────────────────────────────────
# Test 3: PR comment truncation
# ────────────────────────────────────────────────────────────────────────────
Dir.mktmpdir("ff-render-") do |input, _|
  output = File.join(input, "out")
  failures = (1..500).map do |i|
    sample_failure(formula: "fake_#{i}",
                   path: "Formulas/google/fake_#{i}.yml",
                   url: "https://fonts.gstatic.com/file_#{i}_with_long_name.woff2",
                   message: "Not Found (404)")
  end
  write_result(input, "urls.json",
               sample_result(check: "urls", failures: failures))

  out = run_renderer(input, output,
                     budget: 5000, # tight budget to force truncation
                     run_url: "https://example/run/3")
  pr = out["pr-comment.md"]
  assert_lt("truncation: pr under budget", pr.size, 5000)
  assert_includes("truncation: shows truncation note", pr, "Showing")
  assert_includes("truncation: links to artifacts", pr, "workflow artifacts")

  # Issue body should NOT be truncated — should contain ALL failures
  issue = out["issue-body.md"]
  (1..500).each do |i|
    unless issue.include?("fake_#{i}")
      $fail += 1
      warn "FAIL: issue-body missing failure ##{i}"
      break
    end
  end
  $pass += 1 if issue.include?("fake_500")
end

# ────────────────────────────────────────────────────────────────────────────
# Test 4: singular vs plural "failure(s)"
# ────────────────────────────────────────────────────────────────────────────
Dir.mktmpdir("ff-render-") do |input, _|
  output = File.join(input, "out")
  write_result(input, "schema.json",
               sample_result(check: "schema",
                             failures: [sample_failure(formula: "solo")]))
  write_result(input, "urls.json",
               sample_result(check: "urls",
                             failures: [
                               sample_failure(formula: "a"),
                               sample_failure(formula: "b"),
                             ]))

  out = run_renderer(input, output)
  assert_includes("singular: '1 failure'", out["pr-comment.md"], "Schema</b> — 1 failure")
  assert_includes("plural: '2 failures'", out["pr-comment.md"], "URLs</b> — 2 failures")
end

# ────────────────────────────────────────────────────────────────────────────
# Test 5: malformed JSON is skipped with warning, others still render
# ────────────────────────────────────────────────────────────────────────────
Dir.mktmpdir("ff-render-") do |input, _|
  output = File.join(input, "out")
  write_result(input, "schema.json", sample_result(check: "schema"))
  File.write(File.join(input, "broken.json"), "{ not valid json")
  out = run_renderer(input, output)
  assert("malformed: still produces pr-comment", !out["pr-comment.md"].nil?)
  assert_includes("malformed: valid check still in report", out["pr-comment.md"], "Schema")
end

# ────────────────────────────────────────────────────────────────────────────
# Test 6: empty input directory
# ────────────────────────────────────────────────────────────────────────────
Dir.mktmpdir("ff-render-") do |input, _|
  output = File.join(input, "out")
  out = run_renderer(input, output)
  assert("empty: pr-comment still written", !out["pr-comment.md"].nil?)
end

# ────────────────────────────────────────────────────────────────────────────
# Test 7: step-summary shows top-N
# ────────────────────────────────────────────────────────────────────────────
Dir.mktmpdir("ff-render-") do |input, _|
  output = File.join(input, "out")
  failures = (1..10).map do |i|
    sample_failure(formula: "f#{i}", path: "Formulas/f#{i}.yml", message: "err #{i}")
  end
  write_result(input, "schema.json", sample_result(check: "schema", failures: failures))

  out = run_renderer(input, output)
  summary = out["step-summary.md"]
  assert_includes("step-summary: top-3 marker", summary, "(top 3)")
  assert_includes("step-summary: 'and X more'", summary, "and 7 more")
end

puts
puts "=" * 60
puts "RENDER_REPORT TESTS: #{$pass} passed, #{$fail} failed"
puts "=" * 60
exit($fail.zero? ? 0 : 1)
