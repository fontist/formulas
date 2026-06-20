#!/usr/bin/env ruby
# frozen_string_literal: true

# Font metadata + specimen generation pipeline.
# Uses Fontisan to extract Unicode coverage and generate web-optimized woff2
# specimens for every formula in the catalog.
#
# Two paths:
#   A. Google fonts: resources have source:google with files:[woff2 URLs].
#      Download woff2 directly — already web-optimized, no subsetting needed.
#   B. Non-Google (SIL, manual): resources have urls:[archive URLs].
#      Download archive, extract via excavate, subset + convert via Fontisan.
#
# Outputs:
#   docs/public/coverage/<slug>.json  — Unicode coverage (ALL fonts)
#   docs/public/fonts/<slug>.woff2    — Specimen font (redistributable only)
#   docs/public/font-metadata.json    — Manifest index
#
# Usage:
#   ruby process/generate_font_metadata.rb [--directory Formulas] [--output-dir docs/public]
#                                          [--limit N] [--only path1,path2] [--verbose]

require "yaml"
require "json"
require "fileutils"
require "tmpdir"
require "open-uri"
require "optparse"
require "fontisan"

class FontMetadataGenerator
  REDISTRIBUTABLE_PREFIXES = %w[OFL Apache MIT CC0 UFL BSD GPL LGPL IPA Bitstream GUST CC-BY].freeze

  DISPLAY_SUBSET_TEXT = "ABCDEFGHIJKLMNOPQRSTUVWXYZ" \
                        "abcdefghijklmnopqrstuvwxyz" \
                        "0123456789" \
                        " !\"#\$%&'()*+,-./:;<=>?@[\\]^_{|}~"

  def initialize(args)
    OptionParser.new do |opts|
      opts.banner = "Usage: ruby generate_font_metadata.rb [options]"
      opts.on("--directory DIR", "Formula directory") { |d| @formula_dir = d }
      opts.on("--output-dir DIR", "Output directory") { |d| @output_dir = d }
      opts.on("--limit N", Integer, "Process at most N formulas") { |n| @limit = n }
      opts.on("--only PATHS", "Comma-separated formula paths") { |p| @only = p.split(",") }
      opts.on("--verbose", "Verbose output") { @verbose = true }
    end.parse!

    @formula_dir ||= "Formulas"
    @output_dir ||= "docs/public"
    @limit ||= nil
    @only ||= nil
    @verbose ||= false

    @coverage_dir = File.join(@output_dir, "coverage")
    @fonts_dir = File.join(@output_dir, "fonts")
    @stats = { processed: 0, skipped: 0, failed: 0, woff2_generated: 0 }
  end

  def call
    FileUtils.mkdir_p([@coverage_dir, @fonts_dir])

    formulas = collect_formulas
    puts "Processing #{formulas.size} formulas..." if @verbose

    manifest = []
    formulas.each_with_index do |path, i|
      print "\r[#{i + 1}/#{formulas.size}]" if @verbose && (i % 10).zero?
      entry = process_formula(path)
      manifest << entry if entry
    rescue StandardError => e
      @stats[:failed] += 1
      warn "\nERROR #{path}: #{e.message}" if @verbose
    end

    write_manifest(manifest)
    print_stats
  end

  private

  def collect_formulas
    files = @only || Dir.glob(File.join(@formula_dir, "**/*.yml"))
    files = files.first(@limit) if @limit
    files.sort
  end

  def process_formula(path)
    yaml = YAML.safe_load_file(path, permitted_classes: [Date])
    return nil unless yaml && yaml["resources"]

    slug = derive_slug(path)
    redistributable = redistributable?(yaml)

    Dir.mktmpdir("font-meta-") do |tmp|
      font_files = download_and_extract(yaml, tmp)
      return nil if font_files.empty?

      primary = font_files.first
      coverage = extract_coverage(primary[:path])
      write_coverage(slug, coverage, primary, redistributable)

      woff2_url = nil
      if redistributable
        woff2_url = generate_specimen(primary[:path], slug, primary[:format])
        @stats[:woff2_generated] += 1 if woff2_url
      end

      @stats[:processed] += 1
      {
        slug: slug,
        formula_path: path.sub(%r{^\./}, ""),
        redistributable: redistributable,
        primary_family: primary[:family],
        coverage_file: "coverage/#{slug}.json",
        woff2_file: woff2_url,
      }
    end
  end

  def derive_slug(path)
    path.sub(%r{^#{@formula_dir}/}, "").sub(/\.yml$/, "")
  end

  def redistributable?(yaml)
    spdx = yaml["spdx_license"].to_s
    return false if spdx.empty?

    REDISTRIBUTABLE_PREFIXES.any? { |p| spdx.upcase.start_with?(p.upcase) }
  end

  def download_and_extract(yaml, tmp_dir)
    resources = yaml["resources"] || {}
    resources.each_value.flat_map do |res|
      next [] unless res.is_a?(Hash)

      if res["source"] == "google" && res["files"].is_a?(Array)
        download_google_files(res["files"], tmp_dir)
      elsif res["urls"].is_a?(Array)
        download_archive_files(res["urls"], tmp_dir)
      else
        []
      end
    end
  end

  def download_google_files(urls, tmp_dir)
    urls.first(1).map do |url|
      path = File.join(tmp_dir, "google_#{urls.index(url)}.woff2")
      download(url, path)
      { path: path, family: nil, format: "woff2", source_url: url }
    end
  rescue StandardError => e
    warn "WARN download google: #{e.message}" if @verbose
    []
  end

  def download_archive_files(urls, tmp_dir)
    url = urls.find { |u| u.include?("archive.org") } || urls.first
    archive_path = File.join(tmp_dir, "archive")
    download(url, archive_path)
    extract_archive(archive_path, tmp_dir)
  rescue StandardError => e
    warn "WARN download archive: #{e.message}" if @verbose
    []
  end

  def download(url, dest)
    URI.open(url, "rb", read_timeout: 30, open_timeout: 15) do |src|
      File.binwrite(dest, src.read)
    end
  end

  def extract_archive(archive_path, dest_dir)
    extract_dir = File.join(dest_dir, "extracted")
    FileUtils.mkdir_p(extract_dir)
    fonts = []

    require "excavate"
    Dir.chdir(extract_dir) do
      Excavate::Archive.new(archive_path).extract
    end
    Dir.glob(File.join(extract_dir, "**/*.{ttf,otf,woff,woff2}")).each do |f|
      fonts << { path: f, family: nil, format: File.extname(f).delete("."), source_url: nil }
    end
    fonts
  rescue LoadError
    warn "WARN: excavate gem not available — skipping archive extraction" if @verbose
    []
  rescue StandardError => e
    warn "WARN extract: #{e.message}" if @verbose
    []
  end

  def extract_coverage(font_path)
    font = Fontisan::FontLoader.load(font_path)
    cmap = font.table("cmap")
    codepoints = cmap ? cmap.unicode_mappings.keys : []

    {
      total_codepoints: codepoints.length,
      supported_blocks: count_blocks(codepoints),
      planes: detect_planes(codepoints),
      codepoints: codepoints,
    }
  rescue StandardError => e
    warn "WARN coverage: #{e.message}" if @verbose
    { total_codepoints: 0, supported_blocks: 0, planes: {}, codepoints: [] }
  end

  def count_blocks(codepoints)
    codepoints.each_with_object({}) do |cp, blocks|
      block = block_name_for(cp)
      next unless block

      blocks[block] = (blocks[block] || 0) + 1
    end.size
  end

  def detect_planes(codepoints)
    { bmp: codepoints.any? { |cp| cp <= 0xFFFF },
      smp: codepoints.any? { |cp| cp > 0xFFFF && cp <= 0x1FFFF },
      sip: codepoints.any? { |cp| cp > 0x1FFFF && cp <= 0x2FFFF } }
  end

  def block_name_for(cp)
    @blocks ||= load_unicode_blocks
    @blocks.bsearch { |b| cp < b[:start] ? -1 : (cp > b[:end_] ? 1 : 0) }
    &.dig(:name)
  end

  def load_unicode_blocks
    path = File.join(__dir__, "..", "vendor", "unicode-blocks.json")
    if File.exist?(path)
      JSON.parse(File.read(path)).map { |b| { start: b["start"], end_: b["end"], name: b["name"] } }
    else
      []
    end
  end

  def write_coverage(slug, coverage, font_info, redistributable)
    data = coverage.merge(
      slug: slug,
      redistributable: redistributable,
      source_format: font_info[:format],
      source_url: font_info[:source_url],
    )
    path = File.join(@coverage_dir, "#{slug}.json")
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, JSON.pretty_generate(data))
  end

  def generate_specimen(font_path, slug, source_format)
    return copy_if_woff2(font_path, slug) if source_format == "woff2"

    subset_path = File.join(Dir.mktmpdir, "#{slug}.subset.ttf")
    woff2_path = File.join(@fonts_dir, "#{slug}.woff2")
    FileUtils.mkdir_p(File.dirname(woff2_path))

    Fontisan::Commands::SubsetCommand.new(
      font_path, text: DISPLAY_SUBSET_TEXT, output: subset_path,
      profile: "web", drop_hints: true
    ).run

    Fontisan::Commands::ConvertCommand.new(
      subset_path, to: "woff2", output: woff2_path
    ).run

    File.delete(subset_path) if File.exist?(subset_path)
    "fonts/#{slug}.woff2"
  rescue StandardError => e
    warn "WARN specimen for #{slug}: #{e.message}" if @verbose
    nil
  end

  def copy_if_woff2(font_path, slug)
    dest = File.join(@fonts_dir, "#{slug}.woff2")
    FileUtils.mkdir_p(File.dirname(dest))
    FileUtils.cp(font_path, dest)
    "fonts/#{slug}.woff2"
  end

  def write_manifest(manifest)
    path = File.join(@output_dir, "font-metadata.json")
    File.write(path, JSON.pretty_generate(
      generated_at: Time.now.utc.iso8601,
      total_fonts: manifest.size,
      redistributable: manifest.count { |m| m[:redistributable] },
      fonts: manifest,
    ))
    puts "\nManifest: #{path}" if @verbose
  end

  def print_stats
    puts "Processed: #{@stats[:processed]}"
    puts "Skipped:   #{@stats[:skipped]}"
    puts "Failed:    #{@stats[:failed]}"
    puts "woff2:     #{@stats[:woff2_generated]}"
  end
end

FontMetadataGenerator.new(ARGV.dup).call
