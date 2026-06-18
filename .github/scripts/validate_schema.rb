#!/usr/bin/env ruby
# frozen_string_literal: true

# Schema validation for fontist formulas (v5 schema)
# Validates YAML syntax and schema structure for all formulas

require "yaml"
require "optparse"
require "date"

class ValidateSchema
  SCHEMA_V5_REQUIRED_FIELDS = %w[resources].freeze
  FONT_REQUIRED_FIELDS = %w[name styles].freeze
  STYLE_REQUIRED_FIELDS = %w[family_name type font].freeze

  # Top-level 'name' is optional in v5 - it can be derived from fonts[0].name
  # But we should warn if it's missing for clarity
  SCHEMA_V5_OPTIONAL_BUT_RECOMMENDED = %w[name description].freeze

  CATEGORY_STYLES = %w[serif sans-serif monospace display script handwriting decorative].freeze
  CATEGORY_SCRIPTS = %w[latin cjk arabic cyrillic hebrew devanagari thai other].freeze
  CATEGORY_USE_CASES = %w[body heading code ui decorative caption].freeze

  def initialize(args)
    OptionParser.new do |opts|
      opts.banner = "Usage: ruby validate_schema.rb [options]"

      opts.on("--directory DIR", "Directory to scan for formulas") do |dir|
        @directory = dir
      end

      opts.on("--fail-fast", "Stop on first error") do
        @fail_fast = true
      end
    end.parse!

    @directory ||= "Formulas"
    @fail_fast ||= false
    @errors = []
    @warnings = []
    @total = 0
    @passed = 0
  end

  def call
    puts "Validating formula schemas in: #{@directory}"
    puts "=" * 60

    formula_files.each do |file|
      @total += 1
      validate_file(file)

      if @fail_fast && @errors.any?
        print_results
        exit 1
      end
    end

    print_results
    exit 1 if @errors.any?
  end

  private

  def formula_files
    Dir.glob(File.join(@directory, "**/*.yml")).sort
  end

  def validate_file(file)
    content = load_yaml(file)
    return unless content

    schema_version = content["schema_version"] || 4

    # Validate based on schema version
    if schema_version >= 5
      validate_v5_schema(file, content)
    else
      validate_v4_schema(file, content)
    end

    validate_fonts_or_collections(file, content)

    validate_categories(file, content)

    # Common validations
    validate_fonts(file, content)
    validate_naming(file, content)

    @passed += 1 if @errors.none? { |e| e[:file] == file }
  rescue StandardError => e
    add_error(file, "Unexpected error: #{e.message}")
  end

  def load_yaml(file)
    YAML.safe_load_file(file, permitted_classes: [Date])
  rescue Psych::SyntaxError => e
    add_error(file, "YAML syntax error: #{e.message}")
    nil
  end

  def validate_v5_schema(file, content)
    SCHEMA_V5_REQUIRED_FIELDS.each do |field|
      unless content[field]
        add_error(file, "Missing required field: #{field}")
      end
    end

    # Warn about missing optional-but-recommended fields
    SCHEMA_V5_OPTIONAL_BUT_RECOMMENDED.each do |field|
      unless content[field]
        add_warning(file, "Missing recommended field: #{field}")
      end
    end

    # Validate resources structure (v5 style)
    resources = content["resources"]
    return unless resources

    resources.each do |name, resource|
      validate_v5_resource(file, name, resource)
    end
  end

  def validate_categories(file, content)
    categories = content["categories"]
    return unless categories

    unless categories.is_a?(Hash)
      add_error(file, "categories must be a mapping (hash), got #{categories.class}")
      return
    end

    validate_category_enum(file, categories, "style", CATEGORY_STYLES, array: false)
    validate_category_enum(file, categories, "script", CATEGORY_SCRIPTS, array: true)
    validate_category_enum(file, categories, "use_case", CATEGORY_USE_CASES, array: false)

    return unless categories.key?("variable") &&
                  ![true, false].include?(categories["variable"])

    add_error(file, "categories.variable must be boolean, " \
                    "got #{categories["variable"].inspect}")
  end

  def validate_category_enum(file, categories, key, allowed, array:)
    return unless categories.key?(key)

    value = categories[key]
    values = array ? normalize_array(value, key) : [value]
    return if values.nil?

    values.each do |v|
      next if allowed.include?(v)

      add_warning(file, "categories.#{key} unknown value '#{v}' " \
                        "— allowed: #{allowed.join(', ')}")
    end
  end

  def normalize_array(value, key)
    return [value] unless value.is_a?(Array)

    value
  rescue StandardError
    add_error(file, "categories.#{key} must be string or array")
    nil
  end

  def validate_v5_resource(file, name, resource)
    # Google-sourced resources
    if resource["source"] == "google"
      unless resource["family"]
        add_error(file, "Google resource '#{name}' missing 'family' field")
      end

      unless resource["files"].is_a?(Array)
        add_error(file, "Google resource '#{name}' must have 'files' array")
      end

      unless resource["format"]
        add_warning(file, "Google resource '#{name}' missing 'format' field")
      end
    else
      # URL-based resources (legacy v4 style still supported)
      unless resource["urls"] || resource["url"]
        add_error(file, "Resource '#{name}' must have 'urls' or 'url' field")
      end

      if resource["urls"] && !resource["sha256"]
        add_warning(file, "Resource '#{name}' missing SHA256 checksum")
      end
    end
  end

  def validate_v4_schema(file, content)
    %w[name resources].each do |field|
      unless content[field]
        add_error(file, "Missing required field: #{field}")
      end
    end

    validate_fonts_or_collections(file, content)
  end

  def validate_fonts_or_collections(file, content)
    unless content["fonts"] || content["font_collections"]
      add_error(file, "Missing required field: fonts or font_collections")
    end
  end

  def validate_fonts(file, content)
    fonts = content["fonts"]
    return unless fonts

    fonts.each_with_index do |font, idx|
      FONT_REQUIRED_FIELDS.each do |field|
        unless font[field]
          add_error(file, "Font #{idx} missing required field: #{field}")
        end
      end

      styles = font["styles"]
      next unless styles

      styles.each_with_index do |style, sidx|
        STYLE_REQUIRED_FIELDS.each do |field|
          unless style[field]
            add_error(file, "Font #{idx} style #{sidx} missing: #{field}")
          end
        end
      end
    end
  end

  def validate_naming(file, content)
    name = content["name"]
    return unless name

    expected_filename = name.downcase.gsub(/[^a-z0-9]+/, "_").gsub(/^_|_$/, "") + ".yml"
    actual_filename = File.basename(file)

    # Extract just the formula name from path
    formula_dir = File.dirname(file)
    formula_path = file.sub(/^Formulas\//, "")

    # For formulas in subdirectories, the filename should match the name
    if actual_filename != expected_filename
      add_warning(file, "Filename '#{actual_filename}' doesn't match " \
                        "expected '#{expected_filename}' from name: #{name}")
    end
  end

  def add_error(file, message)
    @errors << { file: file, message: message }
    puts "  ERROR: #{file}"
    puts "         #{message}"
  end

  def add_warning(file, message)
    @warnings << { file: file, message: message }
    puts "  WARN:  #{file}"
    puts "         #{message}"
  end

  def print_results
    puts
    puts "=" * 60
    puts "VALIDATION RESULTS"
    puts "=" * 60
    puts "Total formulas:  #{@total}"
    puts "Passed:          #{@passed}"
    puts "Errors:          #{@errors.size}"
    puts "Warnings:        #{@warnings.size}"

    if @errors.any?
      puts
      puts "FAILED FORMULAS:"
      @errors.group_by { |e| e[:file] }.each do |file, errs|
        puts "  #{file}"
        errs.each { |e| puts "    - #{e[:message]}" }
      end
    end

    if @warnings.any?
      puts
      puts "WARNINGS (first 20):"
      @warnings.first(20).each do |w|
        puts "  #{w[:file]}: #{w[:message]}"
      end
      puts "  ... and #{@warnings.size - 20} more" if @warnings.size > 20
    end

    puts
    if @errors.empty?
      puts "All formulas passed schema validation."
    else
      puts "Schema validation FAILED."
    end
  end
end

ValidateSchema.new(ARGV.dup).call
