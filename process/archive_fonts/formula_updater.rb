# frozen_string_literal: true

module ArchiveFonts
  class FormulaUpdater
    def has_mirror?(formula_path, mirror_url)
      return false unless File.exist?(formula_path)

      File.read(formula_path).include?(mirror_url)
    end

    def add_mirror(formula_path, original_url, mirror_url, dry_run: false)
      return false unless File.exist?(formula_path)

      content = File.read(formula_path)
      return false if content.include?(mirror_url)
      return false unless content.include?("    - #{original_url}")

      updated = content.sub("    - #{original_url}", "    - #{original_url}\n    - #{mirror_url}")

      if dry_run
        puts "  [DRY RUN] Would add mirror to #{formula_path}: #{mirror_url}"
        return true
      end

      File.write(formula_path, updated)
      puts "  Added mirror to #{formula_path}: #{mirror_url}"
      true
    end

    def replace_with_mirror(formula_path, original_url, mirror_url, dry_run: false)
      return false unless File.exist?(formula_path)

      content = File.read(formula_path)
      return false unless content.include?("    - #{original_url}")

      if content.include?(mirror_url)
        remove_url(formula_path, original_url, dry_run: dry_run, content: content)
      else
        updated = content.sub("    - #{original_url}", "    - #{mirror_url}")
        if dry_run
          puts "  [DRY RUN] Would replace dead URL in #{formula_path}"
          puts "    Remove: #{original_url}"
          puts "    Keep:   #{mirror_url}"
        else
          File.write(formula_path, updated)
          puts "  Replaced dead URL in #{formula_path}"
          puts "    Removed: #{original_url}"
          puts "    Now:     #{mirror_url}"
        end
      end

      true
    end

    private

    def remove_url(formula_path, url, dry_run: false, content: nil)
      content ||= File.read(formula_path)
      line = "    - #{url}\n"
      return false unless content.include?(line)

      updated = content.sub(line, "")
      if dry_run
        puts "  [DRY RUN] Would remove dead URL from #{formula_path}: #{url}"
      else
        File.write(formula_path, updated)
        puts "  Removed dead URL from #{formula_path}: #{url}"
      end

      true
    end
  end
end
