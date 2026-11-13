# frozen_string_literal: true

require "yaml"

module ArchiveFonts
  class URLCollector
    GOOGLE_DIR = "google"

    def from_directory(dir, group: nil)
      paths = glob_formulas(dir, group: group)
      collect_from_paths(paths)
    end

    def from_formula(path)
      collect_from_paths([path])
    end

    private

    def glob_formulas(dir, group: nil)
      case group
      when "manual"
        Dir.glob(File.join(dir, "*.yml"))
      when "sil"
        Dir.glob(File.join(dir, "sil", "*.yml"))
      when "macos"
        Dir.glob(File.join(dir, "macos", "*.yml"))
      else
        Dir.glob(File.join(dir, "**/*.yml")).reject { |p| p.include?("/#{GOOGLE_DIR}/") }
      end
    end

    def collect_from_paths(paths)
      url_map = {}

      paths.each do |path|
        next if path.include?("BACKUP")
        content = YAML.load_file(path)
        next unless content.is_a?(Hash) && content["resources"]

        content["resources"].each do |res_key, res|
          next unless res.is_a?(Hash) && res["urls"]
          res["urls"].each do |url|
            next if url.include?("web.archive.org")
            next if url.include?("archive.org")

            key = url
            if url_map.key?(key)
              url_map[key][:formulas] = (url_map[key][:formulas] + [path]).uniq
            else
              url_map[key] = {
                url: url,
                resource_key: res_key,
                formulas: [path],
              }
            end
          end
        end
      end

      url_map.values
    end
  end
end
