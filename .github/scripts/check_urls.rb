#!/usr/bin/env ruby
# frozen_string_literal: true

# URL accessibility check for fontist formulas
# Performs HEAD requests to verify font URLs are accessible

require "yaml"
require "net/http"
require "uri"
require "optparse"
require "date"
require "concurrent"
require "json"
require "fileutils"

class CheckUrls
  TIMEOUT_SECONDS = 10
  MAX_RETRIES = 2
  RETRY_DELAY = 2
  MAX_CONCURRENT = 10

  def initialize(args)
    OptionParser.new do |opts|
      opts.banner = "Usage: ruby check_urls.rb [options]"

      opts.on("--directory DIR", "Directory to scan for formulas") do |dir|
        @directory = dir
      end

      opts.on("--timeout SECONDS", Integer, "Request timeout") do |timeout|
        @timeout = timeout
      end

      opts.on("--sample N", Integer, "Only check N formulas randomly") do |n|
        @sample_size = n
      end

      opts.on("--google-only", "Only check Google fonts") do
        @google_only = true
      end

      opts.on("--verbose", "Show all URLs checked") do
        @verbose = true
      end

      opts.on("--json-output FILE", "Write structured results as JSON") do |file|
        @json_output = file
      end

      opts.on("--only PATHS", "Comma-separated list of formula paths (skip glob)") do |paths|
        @only = paths.split(",").map(&:strip)
      end
    end.parse!

    @directory ||= "Formulas"
    @timeout ||= TIMEOUT_SECONDS
    @sample_size ||= nil
    @google_only ||= false
    @verbose ||= false
    @json_output ||= nil

    @errors = []
    @warnings = []
    @checked_urls = {}
    @mutex = Mutex.new
    @started_at = Time.now.utc
  end

  def call
    puts "Checking URL accessibility in: #{@directory}"
    puts "Timeout: #{@timeout}s, Max concurrent: #{MAX_CONCURRENT}"
    puts "=" * 60

    formulas = collect_formulas
    formulas = sample_formulas(formulas) if @sample_size

    puts "Checking #{formulas.size} formulas..."
    puts

    # Process formulas concurrently
    pool = Concurrent::FixedThreadPool.new(MAX_CONCURRENT)
    futures = formulas.map do |formula|
      Concurrent::Future.execute(executor: pool) do
        check_formula_urls(formula)
      end
    end

    # Wait for all to complete
    futures.each(&:value!)
    pool.shutdown
    pool.wait_for_termination

    print_results
    write_json_results(formulas.size) if @json_output

    exit 1 if @errors.any?
  end

  private

  def collect_formulas
    files = if @only
              @only.select { |f| File.exist?(f) }
            else
              Dir.glob(File.join(@directory, "**/*.yml"))
            end

    files.select do |file|
      next false if file.include?("BACKUP")

      if @google_only
        file.include?("/google/")
      else
        true
      end
    end.sort
  end

  def sample_formulas(formulas)
    formulas.sample(@sample_size)
  end

  def check_formula_urls(file)
    content = YAML.safe_load_file(file, permitted_classes: [Date])
    return unless content

    urls = extract_urls(content)
    return if urls.empty?

    formula_name = content["name"] || File.basename(file, ".yml")

    urls.each do |url|
      next if already_checked?(url)

      result = check_url(url)

      @mutex.synchronize do
        if result[:status] == :error
          @errors << { file: file, url: url, message: result[:message] }
          puts "  FAIL: #{formula_name}"
          puts "        #{url}"
          puts "        #{result[:message]}"
        elsif result[:status] == :warning
          @warnings << { file: file, url: url, message: result[:message] }
          puts "  WARN: #{formula_name} - #{result[:message]}" if @verbose
        elsif @verbose
          puts "  OK:   #{formula_name}"
        end
      end
    end
  rescue StandardError => e
    @mutex.synchronize do
      @errors << { file: file, url: "N/A", message: "Parse error: #{e.message}" }
    end
  end

  def extract_urls(content)
    urls = []
    resources = content["resources"]
    return urls unless resources

    resources.each do |_name, resource|
      # v5 Google-style: files array
      if resource["files"].is_a?(Array)
        urls.concat(resource["files"])
      end

      # v4 URL-based: urls array
      if resource["urls"].is_a?(Array)
        urls.concat(resource["urls"])
      end

      # Single URL
      urls << resource["url"] if resource["url"]
    end

    urls.compact.uniq
  end

  def already_checked?(url)
    @mutex.synchronize do
      if @checked_urls.key?(url)
        return true
      end
      @checked_urls[url] = :checking
      false
    end
  end

  def check_url(url)
    uri = URI.parse(url)

    unless %w[http https].include?(uri.scheme)
      @mutex.synchronize { @checked_urls[url] = :warning }
      return { status: :warning, message: "Non-HTTP URL" }
    end

    retries = 0
    redirects = 0

    loop do
      response = nil
      begin
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = (uri.scheme == "https")
        http.open_timeout = @timeout
        http.read_timeout = @timeout

        request = Net::HTTP::Head.new(uri.request_uri)
        request["User-Agent"] = "fontist-formula-check/1.0"

        response = http.request(request)
      rescue Net::OpenTimeout, Net::ReadTimeout
        retries += 1
        if retries <= MAX_RETRIES
          sleep(RETRY_DELAY)
          next
        end
        @mutex.synchronize { @checked_urls[url] = :error }
        return { status: :error, message: "Timeout after #{@timeout}s" }
      rescue SocketError => e
        @mutex.synchronize { @checked_urls[url] = :error }
        return { status: :error, message: "DNS/Network error: #{e.message}" }
      rescue StandardError => e
        @mutex.synchronize { @checked_urls[url] = :error }
        return { status: :error, message: "Error: #{e.message}" }
      end

      case response.code.to_i
      when 200..299
        @mutex.synchronize { @checked_urls[url] = :ok }
        return { status: :ok, message: "OK (#{response.code})" }
      when 301, 302, 303, 307, 308
        location = response["Location"]
        if location && redirects < 3
          redirects += 1
          uri = URI.parse(location)
          next
        end
        @mutex.synchronize { @checked_urls[url] = :warning }
        return { status: :warning, message: "Redirect (#{response.code}) -> #{location}" }
      when 403
        @mutex.synchronize { @checked_urls[url] = :warning }
        return { status: :warning, message: "Forbidden (403) - may need special headers" }
      when 404
        @mutex.synchronize { @checked_urls[url] = :error }
        return { status: :error, message: "Not Found (404)" }
      when 429
        @mutex.synchronize { @checked_urls[url] = :warning }
        return { status: :warning, message: "Rate Limited (429)" }
      when 500..599
        @mutex.synchronize { @checked_urls[url] = :error }
        return { status: :error, message: "Server Error (#{response.code})" }
      else
        @mutex.synchronize { @checked_urls[url] = :warning }
        return { status: :warning, message: "Unexpected status: #{response.code}" }
      end
    end
  end

  def print_results
    puts
    puts "=" * 60
    puts "URL CHECK RESULTS"
    puts "=" * 60
    puts "URLs checked:    #{@checked_urls.size}"
    puts "Errors:          #{@errors.size}"
    puts "Warnings:        #{@warnings.size}"

    if @errors.any?
      puts
      puts "FAILED URLs:"
      @errors.group_by { |e| e[:file] }.each do |file, errs|
        puts "  #{file}"
        errs.each { |e| puts "    - #{e[:url]}: #{e[:message]}" }
      end
    end

    if @warnings.any? && @warnings.size <= 20
      puts
      puts "WARNINGS:"
      @warnings.each { |w| puts "  #{w[:url]}: #{w[:message]}" }
    end

    puts
    if @errors.empty?
      puts "All URLs are accessible."
    else
      puts "URL check FAILED."
    end
  end

  def write_json_results(total_formulas)
    failures = @errors.map do |e|
      {
        "formula" => derive_formula_name(e[:file]),
        "formula_path" => relativise(e[:file]),
        "url" => e[:url],
        "message" => e[:message],
        "severity" => "error",
      }
    end

    warnings = @warnings.map do |w|
      {
        "formula" => derive_formula_name(w[:file]),
        "formula_path" => relativise(w[:file]),
        "url" => w[:url],
        "message" => w[:message],
        "severity" => "warning",
      }
    end

    data = {
      "check" => "urls",
      "platform" => "all",
      "scope" => @google_only ? "google" : derive_scope_from_dir,
      "started_at" => @started_at.iso8601,
      "completed_at" => Time.now.utc.iso8601,
      "summary" => {
        "total" => @checked_urls.size,
        "passed" => @checked_urls.size - @errors.size - @warnings.size,
        "failed" => @errors.size,
        "warnings" => @warnings.size,
        "skipped" => 0,
      },
      "failures" => failures,
      "warnings" => warnings,
    }

    FileUtils.mkdir_p(File.dirname(@json_output))
    File.write(@json_output, JSON.pretty_generate(data))
    puts "JSON results written to: #{@json_output}"
  end

  def derive_formula_name(file)
    File.basename(file, ".yml")
  end

  def relativise(file)
    file.sub(%r{^\./}, "")
  end

  def derive_scope_from_dir
    case @directory
    when %r{google}i then "google"
    when %r{sil}i then "sil"
    when %r{macos}i then "macos"
    else "all"
    end
  end
end

CheckUrls.new(ARGV.dup).call
