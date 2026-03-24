#!/usr/bin/env ruby
# frozen_string_literal: true

# Full installation test for fontist formulas with rotation support
# Tests formula installation by actually downloading and installing fonts

require "yaml"
require "tmpdir"
require "optparse"
require "fileutils"
require "time"
require "fontist"

class InstallFormulas
  ROTATION_DAY_1_PATTERNS = [/^a/i, /^b/i, /^c/i, /^d/i, /^e/i, /^f/i,
                             /^g/i, /^h/i, /^i/i, /^j/i, /^k/i, /^l/i,
                             /^m/i].freeze

  def initialize(args)
    OptionParser.new do |opts|
      opts.banner = "Usage: ruby install_formulas.rb [options]"

      opts.on("--directory DIR", "Directory to scan for formulas") do |dir|
        @directory = dir
      end

      opts.on("--platform PLATFORM", "Test formulas for PLATFORM") do |platform|
        @platform = platform
      end

      opts.on("--every-platform", "Test formulas without platform restriction") do
        @every_platform = true
      end

      opts.on("--rotation DAY", Integer, "Rotation day (1 or 2)") do |day|
        @rotation_day = day
      end

      opts.on("--group GROUP", "Test specific group (google, sil, macos, other)") do |group|
        @group = group
      end

      opts.on("--sample N", Integer, "Only test N formulas randomly") do |n|
        @sample_size = n
      end

      opts.on("--continue-on-error", "Don't stop on errors") do
        @continue_on_error = true
      end

      opts.on("--output FILE", "Write results to file") do |file|
        @output_file = file
      end
    end.parse!

    @directory ||= "Formulas"
    @platform ||= nil
    @every_platform ||= false
    @rotation_day ||= calculate_rotation_day
    @group ||= nil
    @sample_size ||= nil
    @continue_on_error ||= false
    @output_file ||= nil

    @errors = []
    @successes = []
    @skipped = []
    @mutex = Mutex.new
  end

  def call
    puts "=" * 60
    puts "FORMULA INSTALLATION TEST"
    puts "=" * 60
    puts "Directory:     #{@directory}"
    puts "Platform:      #{@platform || 'all'}"
    puts "Rotation day:  #{@rotation_day}"
    puts "Group filter:  #{@group || 'none'}"
    puts "=" * 60
    puts

    formulas = collect_formulas
    formulas = filter_by_rotation(formulas)
    formulas = filter_by_group(formulas)
    formulas = sample_formulas(formulas)

    puts "Testing #{formulas.size} formulas..."
    puts

    create_fontist_home do
      copy_all_formulas
      rebuild_index

      formulas.each do |formula_path|
        test_formula(formula_path)
      end
    end

    print_results
    write_results if @output_file

    exit 1 if @errors.any? && !@continue_on_error
  end

  private

  def calculate_rotation_day
    # Day 1 or 2 based on day of year
    (Time.now.yday % 2) + 1
  end

  def collect_formulas
    Dir.glob(File.join(@directory, "**/*.yml")).select do |file|
      !file.include?("BACKUP")
    end.sort
  end

  def filter_by_rotation(formulas)
    return formulas unless @rotation_day

    formulas.select do |file|
      # Get formula name from file
      basename = File.basename(file, ".yml")

      if file.include?("/google/")
        # Google fonts: split by first letter
        if @rotation_day == 1
          ROTATION_DAY_1_PATTERNS.any? { |p| basename.match?(p) }
        else
          ROTATION_DAY_1_PATTERNS.none? { |p| basename.match?(p) }
        end
      else
        # Non-Google: test on day 2 only
        @rotation_day == 2
      end
    end
  end

  def filter_by_group(formulas)
    return formulas unless @group

    case @group.downcase
    when "google"
      formulas.select { |f| f.include?("/google/") }
    when "sil"
      formulas.select { |f| f.include?("/sil/") }
    when "macos"
      formulas.select { |f| f.include?("/macos/") }
    when "other"
      formulas.reject { |f| f.include?("/google/") || f.include?("/sil/") ||
                             f.include?("/macos/") }
    else
      formulas
    end
  end

  def sample_formulas(formulas)
    return formulas unless @sample_size

    formulas.sample(@sample_size)
  end

  def create_fontist_home
    Dir.mktmpdir("fontist-test-") do |dir|
      ENV["FONTIST_PATH"] = dir

      yield dir

      ENV["FONTIST_PATH"] = nil
    end
  end

  def copy_all_formulas
    puts "Copying formulas to Fontist home..."

    # Copy all formulas to maintain directory structure
    # Fontist expects formulas to be under "Formulas/" in the repo path
    Dir.glob(File.join(@directory, "**/*.yml")).each do |formula|
      next if formula.include?("BACKUP")

      # Keep the full path including "Formulas/" prefix
      dest = Fontist.formulas_repo_path.join(formula)
      dest_dir = File.dirname(dest)

      FileUtils.mkdir_p(dest_dir)
      FileUtils.cp(formula, dest)
    end
  end

  def rebuild_index
    puts "Rebuilding Fontist index..."
    Fontist::Index.rebuild
  end

  def test_formula(formula_path)
    content = load_formula(formula_path)
    return unless content

    formula_name = content["name"] || File.basename(formula_path, ".yml")

    # Skip non-downloadable formulas
    unless downloadable?(content)
      @mutex.synchronize { @skipped << formula_name }
      return
    end

    # Skip platform-specific formulas
    unless matches_platform?(content)
      @mutex.synchronize { @skipped << "#{formula_name} (platform mismatch)" }
      return
    end

    puts "Testing: #{formula_name}"

    begin
      install_formula(formula_path, formula_name)
      @mutex.synchronize { @successes << formula_name }
      puts "  OK"
    rescue StandardError => e
      @mutex.synchronize { @errors << { name: formula_name, error: e.message } }
      puts "  FAILED: #{e.message}"

      raise unless @continue_on_error
    end
  end

  def load_formula(path)
    YAML.load_file(path)
  rescue StandardError => e
    @mutex.synchronize { @errors << { name: path, error: "Parse error: #{e.message}" } }
    nil
  end

  def downloadable?(content)
    !!content["resources"]
  end

  def matches_platform?(content)
    return true if @every_platform && content["platforms"].nil?
    return true unless @platform

    platforms = content["platforms"]
    return true if platforms.nil?

    platforms.any? { |p| p.downcase.start_with?(@platform.downcase) }
  end

  def install_formula(formula_path, formula_name)
    # Convert file path to formula name for fontist
    relative = formula_path.sub(/^#{@directory}\//, "").sub(/\.yml$/, "")

    Fontist.log_level = :info

    Fontist::Font.install(
      relative,
      formula: true,
      force: true,
      confirmation: "yes",
      hide_licenses: true,
      no_progress: true,
    )
  end

  def print_results
    puts
    puts "=" * 60
    puts "INSTALLATION TEST RESULTS"
    puts "=" * 60
    puts "Successes: #{@successes.size}"
    puts "Failures:  #{@errors.size}"
    puts "Skipped:   #{@skipped.size}"

    if @errors.any?
      puts
      puts "FAILED FORMULAS:"
      @errors.each do |err|
        puts "  #{err[:name]}"
        puts "    Error: #{err[:error].split("\n").first}"
      end
    end

    if @skipped.any? && @skipped.size <= 20
      puts
      puts "SKIPPED:"
      @skipped.first(20).each { |s| puts "  #{s}" }
      puts "  ... and #{@skipped.size - 20} more" if @skipped.size > 20
    end

    puts
    if @errors.empty?
      puts "All tested formulas installed successfully."
    else
      puts "Installation test FAILED for #{@errors.size} formulas."
    end
  end

  def write_results
    results = {
      timestamp: Time.now.utc.iso8601,
      rotation_day: @rotation_day,
      platform: @platform,
      total_tested: @successes.size + @errors.size,
      successes: @successes,
      failures: @errors,
      skipped: @skipped,
    }

    File.write(@output_file, results.to_yaml)
    puts "\nResults written to: #{@output_file}"
  end
end

InstallFormulas.new(ARGV.dup).call
