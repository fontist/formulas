#!/usr/bin/env ruby
# frozen_string_literal: true

require "yaml"
require "json"
require "net/http"
require "uri"
require "optparse"
require "fileutils"
require "digest"

class ArchiveFonts
  USER_AGENTS = [
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 " \
    "(KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36",
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 " \
    "(KHTML, like Gecko) Chrome/130.0.0.0 Safari/537.36",
    "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 " \
    "(KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36",
  ].freeze

  def initialize(args)
    OptionParser.new do |opts|
      opts.banner = "Usage: ruby archive_fonts.rb [options] [formula_files...]"

      opts.on("--directory DIR", "Scan directory for formulas with failing URLs") do |dir|
        @directory = dir
      end

      opts.on("--urls URL1,URL2", Array, "Specific URLs to archive") do |urls|
        @urls = urls
      end

      opts.on("--formula FILE", "Update a specific formula file with archive.org mirror") do |f|
        @formula_file = f
      end

      opts.on("--mirror-only", "Only add archive.org mirrors, don't download/upload") do
        @mirror_only = true
      end

      opts.on("--check", "Only check which URLs are archived") do
        @check_only = true
      end

      opts.on("--dry-run", "Show what would be done without making changes") do
        @dry_run = true
      end
    end.parse!(args)

    @formula_files = args.empty? ? [] : args
    @directory ||= nil
    @urls ||= []
    @formula_file ||= nil
    @mirror_only ||= false
    @check_only ||= false
    @dry_run ||= false
  end

  def call
    urls = collect_urls
    puts "Found #{urls.size} URLs to process"
    puts

    results = urls.map { |url| process_url(url) }
    print_summary(results)

    update_formulas(results) unless @check_only || @mirror_only
  end

  private

  def collect_urls
    urls = @urls.dup

    if @directory
      Dir.glob(File.join(@directory, "**/*.yml")).each do |f|
        next if f.include?("BACKUP")
        content = YAML.load_file(f)
        next unless content.is_a?(Hash) && content["resources"]

        content["resources"].each_value do |res|
          next unless res.is_a?(Hash) && res["urls"]
          res["urls"].each do |u|
            urls << { url: u, formula: f }
          end
        end
      end
    end

    @formula_files.each do |f|
      content = YAML.load_file(f)
      next unless content.is_a?(Hash) && content["resources"]

      content["resources"].each_value do |res|
        next unless res.is_a?(Hash) && res["urls"]
        res["urls"].each do |u|
          urls << { url: u, formula: f }
        end
      end
    end

    urls.uniq
  end

  def process_url(item)
    url = item.is_a?(Hash) ? item[:url] : item
    formula = item.is_a?(Hash) ? item[:formula] : nil

    puts "Processing: #{url}"

    result = { url: url, formula: formula, archived_url: nil, status: :unknown }

    archived = check_archive(url)
    if archived
      puts "  Already archived: #{archived}"
      valid = validate_archived_url(archived)
      if valid
        result[:archived_url] = archived
        result[:status] = :already_archived
      else
        puts "  Archived snapshot is not valid (404/empty), re-submitting..."
        archived = submit_to_archive(url)
        if archived
          puts "  Re-archived: #{archived}"
          result[:archived_url] = archived
          result[:status] = :newly_archived
        else
          puts "  FAILED to re-archive"
          result[:status] = :failed
        end
      end
    elsif @check_only
      puts "  Not archived"
      result[:status] = :not_archived
    else
      archived = submit_to_archive(url)
      if archived
        puts "  Archived: #{archived}"
        result[:archived_url] = archived
        result[:status] = :newly_archived
      else
        puts "  FAILED to archive"
        result[:status] = :failed
      end
    end

    result
  end

  def check_archive(url)
    api_url = "https://archive.org/wayback/available?url=#{URI.encode_www_form_component(url)}"
    response = http_get(api_url)
    return nil unless response&.code == "200"

    data = JSON.parse(response.body)
    snapshot = data.dig("archived_snapshots", "closest")
    return nil unless snapshot&.dig("available")

    snapshot["url"]
  rescue StandardError => e
    puts "  Check failed: #{e.message}"
    nil
  end

  def validate_archived_url(archived_url)
    response = http_head(archived_url)
    return false unless response
    code = response.code.to_i
    code >= 200 && code < 400
  rescue StandardError
    false
  end

  def submit_to_archive(url)
    save_url = "https://web.archive.org/save/#{url}"
    puts "  Submitting to archive.org..."

    if @dry_run
      puts "  [DRY RUN] Would submit: #{save_url}"
      return "https://web.archive.org/web/placeholder/#{url}"
    end

    uri = URI.parse(save_url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.open_timeout = 30
    http.read_timeout = 120

    request = Net::HTTP::Get.new(uri.request_uri, headers_with_ua)
    response = http.request(request)

    case response.code.to_i
    when 302
      location = response["Location"]
      if location
        location.start_with?("http") ? location : "https://web.archive.org#{location}"
      else
        wait_and_check(url)
      end
    when 200
      content_location = response["Content-Location"]
      if content_location
        content_location.start_with?("http") ? content_location : "https://web.archive.org#{content_location}"
      else
        wait_and_check(url)
      end
    else
      puts "  archive.org returned HTTP #{response.code}"
      nil
    end
  rescue StandardError => e
    puts "  Submit failed: #{e.message}"
    nil
  end

  def wait_and_check(url)
    puts "  Waiting 15s for archive to process..."
    sleep 15
    check_archive(url)
  end

  def update_formulas(results)
    formula_updates = {}
    results.each do |r|
      next unless r[:archived_url] && r[:formula]
      formula_updates[r[:formula]] ||= []
      formula_updates[r[:formula]] << { original: r[:url], mirror: r[:archived_url] }
    end

    formula_updates.each do |formula_file, updates|
      puts "\nUpdating: #{formula_file}"
      content = File.read(formula_file)

      updates.each do |update|
        original = update[:original]
        mirror = update[:mirror]

        if content.include?(mirror)
          puts "  Mirror already present for #{original}"
          next
        end

        # Add mirror URL after the original URL in the YAML
        # The original URL line looks like: "    - https://..."
        if content.include?("    - #{original}")
          if @dry_run
            puts "  [DRY RUN] Would add mirror: #{mirror}"
          else
            content = content.sub("    - #{original}", "    - #{original}\n    - #{mirror}")
            puts "  Added mirror: #{mirror}"
          end
        end
      end

      unless @dry_run
        File.write(formula_file, content)
        puts "  Saved: #{formula_file}"
      end
    end
  end

  def http_get(url)
    uri = URI.parse(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.open_timeout = 15
    http.read_timeout = 30

    request = Net::HTTP::Get.new(uri.request_uri, headers_with_ua)
    http.request(request)
  end

  def http_head(url)
    uri = URI.parse(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.open_timeout = 15
    http.read_timeout = 30

    request = Net::HTTP::Head.new(uri.request_uri, headers_with_ua)
    http.request(request)
  end

  def headers_with_ua
    { "User-Agent" => USER_AGENTS.sample }
  end

  def print_summary(results)
    puts
    puts "=" * 60
    puts "ARCHIVE SUMMARY"
    puts "=" * 60

    counts = results.group_by { |r| r[:status] }
    counts.each { |status, items| puts "  #{status}: #{items.size}" }
    puts

    newly = results.select { |r| r[:status] == :newly_archived || r[:status] == :already_archived }
    if newly.any?
      puts "Archived URLs:"
      newly.each { |r| puts "  #{r[:url]}" }
      puts
      puts "Mirror URLs:"
      newly.each { |r| puts "  #{r[:archived_url]}" if r[:archived_url] }
    end

    failed = results.select { |r| r[:status] == :failed }
    if failed.any?
      puts
      puts "Failed:"
      failed.each { |r| puts "  #{r[:url]}" }
    end
  end
end

ArchiveFonts.new(ARGV.dup).call
