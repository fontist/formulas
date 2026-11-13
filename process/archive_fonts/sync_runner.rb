# frozen_string_literal: true

require "time"
require_relative "registry"
require_relative "url_collector"
require_relative "liveness_checker"
require_relative "archive_client"
require_relative "formula_updater"

module ArchiveFonts
  class SyncRunner
    MAX_SUBMIT_ATTEMPTS = 3

    def initialize(
      registry_path:,
      formula_dir:,
      group: nil,
      batch_size: nil,
      rate_limit: 2,
      check_liveness: false,
      replace_dead: false,
      dry_run: false,
      verbose: false
    )
      @registry_path = registry_path
      @formula_dir = formula_dir
      @group = group
      @batch_size = batch_size
      @rate_limit = rate_limit
      @check_liveness = check_liveness
      @replace_dead = replace_dead
      @dry_run = dry_run
      @verbose = verbose
      @interrupted = false
    end

    def run
      setup_interrupt_handler

      registry = Registry.load(@registry_path)
      client = ArchiveClient.new(rate_limit: @rate_limit)
      checker = @check_liveness ? LivenessChecker.new : nil
      updater = FormulaUpdater.new

      # Phase 1: Gather
      items = gather_urls(registry)
      return if @interrupted

      # Phase 2: Check liveness
      if checker && !@interrupted
        check_all_liveness(items, registry, checker)
      end

      # Phase 3 + 4: Check availability and submit
      process_archiving(items, registry, client) unless @interrupted

      # Phase 5: Update formulas
      update_all_formulas(items, registry, updater) unless @interrupted

      # Phase 6: Save registry
      registry.save
      print_summary(registry)
    rescue Interrupt
      puts "\nInterrupted! Saving registry..."
      @registry&.save
      puts "Registry saved. Run again with --resume to continue."
    end

    private

    def setup_interrupt_handler
      trap("INT") { @interrupted = true }
    end

    def gather_urls(registry)
      collector = URLCollector.new
      items = collector.from_directory(@formula_dir, group: @group)

      # Filter out already-archived entries
      items = items.reject do |item|
        entry = registry.find(item[:url])
        entry&.archived? && !registry.needs_mirror?(item[:url])
      end

      # Apply batch size
      items = items.first(@batch_size) if @batch_size

      puts "Found #{items.size} URLs to process"
      items
    end

    def check_all_liveness(items, registry, checker)
      puts "\n--- Phase 2: Checking liveness ---"
      items.each_with_index do |item, i|
        break if @interrupted

        url = item[:url]
        puts "  [#{i + 1}/#{items.size}] Checking: #{url}" if @verbose

        status = checker.check(url)
        now = Time.now.utc.iso8601

        entry = registry.find(url) || RegistryEntry.new(
          url: url, status: nil, formulas: item[:formulas],
        )
        entry.original_alive = (status == :alive)
        entry.last_checked = now
        registry.upsert(entry)

        puts "    #{status}" if @verbose
      end
    end

    def process_archiving(items, registry, client)
      puts "\n--- Phase 3/4: Checking availability & archiving ---"
      items.each_with_index do |item, i|
        break if @interrupted

        url = item[:url]
        puts "[#{i + 1}/#{items.size}] #{url}"

        entry = registry.find(url) || RegistryEntry.new(
          url: url, status: nil, formulas: item[:formulas],
        )
        entry.formulas = (entry.formulas + item[:formulas]).uniq
        now = Time.now.utc.iso8601

        if entry.archived? && entry.archive_url
          puts "  Already archived" if @verbose
          registry.upsert(entry)
          next
        end

        # Check availability
        archive_url = client.check_availability(url)
        if archive_url
          if client.validate_snapshot(archive_url)
            entry.status = "archived"
            entry.archive_url = archive_url
            entry.last_checked = now
            puts "  Already archived: #{archive_url}"
            registry.upsert(entry)
            next
          else
            puts "  Snapshot invalid, re-submitting..."
          end
        end

        # Submit to archive
        submit_with_retries(url, entry, client, registry, now)
      end
    end

    def submit_with_retries(url, entry, client, registry, now)
      attempts = 0
      loop do
        attempts += 1
        puts "  Submitting (attempt #{attempts})..." if @verbose

        archive_url = client.submit(url)
        if archive_url
          entry.status = "archived"
          entry.archive_url = archive_url
          entry.last_checked = now
          puts "  Archived: #{archive_url}"
          registry.upsert(entry)
          return
        end

        if attempts >= MAX_SUBMIT_ATTEMPTS
          entry.status = "failed"
          entry.last_checked = now
          puts "  FAILED after #{attempts} attempts"
          registry.upsert(entry)
          return
        end

        puts "  Retrying in 10s..."
        sleep(10)
      end
    end

    def update_all_formulas(items, registry, updater)
      puts "\n--- Phase 5: Updating formulas ---"
      updated = 0

      items.each do |item|
        entry = registry.find(item[:url])
        next unless entry&.archived?
        next unless entry.archive_url

        entry.formulas.each do |formula_path|
          if entry.dead? && @replace_dead
            if updater.replace_with_mirror(formula_path, item[:url], entry.archive_url, dry_run: @dry_run)
              updated += 1
            end
          else
            if updater.add_mirror(formula_path, item[:url], entry.archive_url, dry_run: @dry_run)
              updated += 1
            end
          end
        end
      end

      puts "\nUpdated #{updated} formula(s)" if updated > 0
      puts "No formula changes needed" if updated.zero?
    end

    def print_summary(registry)
      counts = registry.count_by_status
      puts "\n#{'=' * 50}"
      puts "REGISTRY SUMMARY"
      puts "#{'=' * 50}"
      puts "  Total URLs: #{registry.entries.size}"
      counts.sort_by { |s, _| s.to_s }.each do |status, count|
        puts "  #{status}: #{count}"
      end
    end
  end
end
