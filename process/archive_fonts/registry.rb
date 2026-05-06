# frozen_string_literal: true

require "yaml"
require "fileutils"
require "time"
require_relative "registry_entry"

module ArchiveFonts
  class Registry
    attr_reader :path, :entries

    def initialize(path)
      @path = path
      @entries = {}
      @metadata = {}
    end

    def self.load(path)
      reg = new(path)
      reg.send(:load!)
      reg
    end

    def find(url)
      entries[url]
    end

    def upsert(entry)
      existing = entries[entry.url]
      if existing
        entry.formulas = (existing.formulas + entry.formulas).uniq
      end
      entries[entry.url] = entry
    end

    def needs_processing?(url)
      entry = entries[url]
      return true unless entry

      entry.status != "archived" && entry.status != "not_archivable"
    end

    def needs_mirror?(url)
      entry = entries[url]
      return true unless entry

      return false unless entry.archived?
      return true if entry.archive_url.nil?

      entry.formulas.any? do |formula_path|
        return true unless File.exist?(formula_path)
        content = File.read(formula_path)
        !content.include?(entry.archive_url)
      end
    end

    def count_by_status
      counts = Hash.new(0)
      entries.each_value { |e| counts[e.status] += 1 }
      counts
    end

    def save
      dir = File.dirname(path)
      FileUtils.mkdir_p(dir) unless Dir.exist?(dir)

      data = build_yaml_data
      yaml = YAML.dump(data)

      tmp = "#{path}.tmp.#{Process.pid}"
      File.write(tmp, yaml)
      File.rename(tmp, path)
    end

    private

    def load!
      return unless File.exist?(path)

      data = YAML.load_file(path)
      return unless data.is_a?(Hash)

      @metadata = data.fetch("_metadata", {})

      data.fetch("entries", {}).each do |url, attrs|
        next unless attrs.is_a?(Hash)
        entries[url] = RegistryEntry.from_h(url, attrs)
      end
    end

    def build_yaml_data
      counts = count_by_status

      metadata = {
        "last_sync" => Time.now.utc.iso8601,
        "total" => entries.size,
      }.merge(counts.transform_keys(&:to_s))

      entries_hash = entries.sort_by { |url, _| url }.to_h do |url, entry|
        [url, entry.to_h]
      end

      { "_metadata" => metadata, "entries" => entries_hash }
    end
  end
end
