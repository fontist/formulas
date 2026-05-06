#!/usr/bin/env ruby
# frozen_string_literal: true

require "thor"
require "yaml"
require "time"
require_relative "archive_fonts/registry"
require_relative "archive_fonts/registry_entry"
require_relative "archive_fonts/url_collector"
require_relative "archive_fonts/liveness_checker"
require_relative "archive_fonts/archive_client"
require_relative "archive_fonts/formula_updater"
require_relative "archive_fonts/sync_runner"

class ArchiveFontsCLI < Thor
  class_option :dry_run, type: :boolean, default: false, desc: "Show changes without making them"
  class_option :verbose, type: :boolean, default: false, desc: "Verbose output"

  desc "sync", "Full pipeline: gather, check, archive, update formulas"
  option :registry, type: :string, default: "process/archive_registry.yml",
                    desc: "Path to registry file"
  option :formula_dir, type: :string, default: "Formulas",
                       desc: "Path to formulas directory"
  option :group, type: :string, desc: "Only process: manual, sil, macos"
  option :check_liveness, type: :boolean, default: false,
                          desc: "HEAD-check if original URLs are alive"
  option :replace_dead, type: :boolean, default: false,
                        desc: "Remove dead originals from formulas"
  option :rate_limit, type: :numeric, default: 2,
                      desc: "Seconds between archive.org save submissions"
  option :batch_size, type: :numeric, desc: "Max new URLs to process per run"
  option :resume, type: :boolean, default: true,
                  desc: "Skip already-processed URLs"
  def sync
    runner = ArchiveFonts::SyncRunner.new(
      registry_path: options[:registry],
      formula_dir: options[:formula_dir],
      group: options[:group],
      batch_size: options[:batch_size],
      rate_limit: options[:rate_limit],
      check_liveness: options[:check_liveness],
      replace_dead: options[:replace_dead],
      dry_run: options[:dry_run],
      verbose: options[:verbose],
    )
    runner.run
  end

  desc "archive URL", "Archive a specific URL to the Wayback Machine"
  option :formula, type: :string, desc: "Formula file to update with mirror"
  option :registry, type: :string, default: "process/archive_registry.yml"
  def archive(url)
    registry = ArchiveFonts::Registry.load(options[:registry])
    client = ArchiveFonts::ArchiveClient.new
    updater = ArchiveFonts::FormulaUpdater.new

    puts "Archiving: #{url}"

    archive_url = client.check_availability(url)
    if archive_url && client.validate_snapshot(archive_url)
      puts "Already archived: #{archive_url}"
    else
      archive_url = client.submit(url)
      if archive_url
        puts "Archived: #{archive_url}"
      else
        puts "FAILED to archive"
        return
      end
    end

    entry = ArchiveFonts::RegistryEntry.new(
      url: url,
      status: "archived",
      archive_url: archive_url,
      original_alive: true,
      last_checked: Time.now.utc.iso8601,
      formulas: options[:formula] ? [options[:formula]] : [],
    )
    registry.upsert(entry)

    if options[:formula]
      updater.add_mirror(options[:formula], url, archive_url, dry_run: options[:dry_run])
    end

    registry.save
    puts "Registry saved."
  end

  desc "check", "Check archival status of URLs"
  option :formula_dir, type: :string, default: "Formulas"
  option :group, type: :string, desc: "Filter: manual, sil, macos"
  def check
    collector = ArchiveFonts::URLCollector.new
    client = ArchiveFonts::ArchiveClient.new

    items = collector.from_directory(options[:formula_dir], group: options[:group])
    puts "Found #{items.size} URLs to check\n\n"

    archived = 0
    not_archived = 0
    failed = 0

    items.each_with_index do |item, i|
      url = item[:url]
      print "[#{i + 1}/#{items.size}] #{url}: "

      archive_url = client.check_availability(url)
      if archive_url
        valid = client.validate_snapshot(archive_url)
        if valid
          puts "archived (#{archive_url})"
          archived += 1
        else
          puts "archived but INVALID"
          not_archived += 1
        end
      else
        puts "NOT archived"
        not_archived += 1
      end
    end

    puts "\n#{'=' * 40}"
    puts "  Archived: #{archived}"
    puts "  Not archived: #{not_archived}"
    puts "  Total: #{items.size}"
  end

  desc "seed", "Seed registry from formulas that already have archive.org mirrors"
  option :registry, type: :string, default: "process/archive_registry.yml"
  option :formula_dir, type: :string, default: "Formulas"
  def seed
    registry = ArchiveFonts::Registry.load(options[:registry])
    seeded = 0

    paths = Dir.glob(File.join(options[:formula_dir], "**/*.yml"))
               .reject { |p| p.include?("/google/") }

    paths.each do |path|
      content = YAML.load_file(path)
      next unless content.is_a?(Hash) && content["resources"]

      content["resources"].each do |_res_key, res|
        next unless res.is_a?(Hash) && res["urls"]

        urls = res["urls"]
        archive_urls = urls.select { |u| u.include?("web.archive.org") }
        original_urls = urls.reject { |u| u.include?("web.archive.org") || u.include?("archive.org") }

        next if archive_urls.empty?

        original_urls.each do |orig|
          entry = ArchiveFonts::RegistryEntry.new(
            url: orig,
            status: "archived",
            archive_url: archive_urls.first,
            original_alive: true,
            last_checked: Time.now.utc.iso8601,
            formulas: [path],
          )
          registry.upsert(entry)
          seeded += 1
        end

        # URLs that are archive-only (dead originals already removed)
        if original_urls.empty?
          archive_urls.each do |au|
            entry = ArchiveFonts::RegistryEntry.new(
              url: au,
              status: "archived",
              archive_url: au,
              original_alive: false,
              last_checked: Time.now.utc.iso8601,
              formulas: [path],
            )
            registry.upsert(entry)
            seeded += 1
          end
        end
      end
    end

    registry.save
    puts "Seeded #{seeded} entries from existing formulas"
    puts "Registry saved to #{options[:registry]}"
  end

  desc "prepare-matrix", "Output JSON matrix of URL chunks for parallel processing"
  option :formula_dir, type: :string, default: "Formulas"
  option :group, type: :string, desc: "Filter: manual, sil, macos"
  option :chunk_size, type: :numeric, default: 50, desc: "URLs per chunk"
  option :registry, type: :string, default: "process/archive_registry.yml"
  def prepare_matrix
    registry = ArchiveFonts::Registry.load(options[:registry])
    collector = ArchiveFonts::URLCollector.new

    items = collector.from_directory(options[:formula_dir], group: options[:group])

    # Filter to only URLs that need processing
    items = items.select do |item|
      entry = registry.find(item[:url])
      !entry&.archived?
    end

    chunk_size = options[:chunk_size]
    chunks = items.each_slice(chunk_size).map.with_index do |slice, i|
      { "index" => i, "urls" => slice.map { |it| it[:url] } }
    end

    require "json"
    puts JSON.generate({ "include" => chunks })
  end

  def self.exit_on_failure?
    true
  end
end

ArchiveFontsCLI.start(ARGV)
