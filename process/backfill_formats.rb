# frozen_string_literal: true

# Backfills v5 format metadata from file names, without downloading archives.
#
#   ruby process/backfill_formats.rb [--dry-run] [--report FILE] FILE_OR_DIR...
#
# - each style without `formats` gets [ext] from its `font` file extension
#   (styles in a font collection use the collection file's extension)
# - a resource without `format` gets one only when every style of the formula
#   has the same single format
# Anything else is left alone and listed in the report.
# Edits are textual so key order and quoting of the files are untouched.

# rubocop:disable Metrics
require "yaml"
require "optparse"

FORMATS = %w[ttf otf ttc otc woff woff2 dfont].freeze

# Edits one formula file.
class FormatBackfill
  attr_reader :changes, :ambiguous

  def initialize(path)
    @path = path
    @lines = File.read(path).lines
    @changes = { styles: 0, resources: 0 }
    @ambiguous = []
  end

  def run
    ast = Psych.parse_file(@path)
    root = ast.root
    return unless root.is_a?(Psych::Nodes::Mapping)

    inserts = []
    style_formats = collect_styles(root, inserts)
    plan_resource(root, style_formats, inserts)
    apply(inserts)
  end

  def changed?
    @changes.values.sum.positive?
  end

  def text
    @lines.join
  end

  private

  def pairs(map)
    map.children.each_slice(2).to_h { |k, v| [k.value, v] }
  end

  def collect_styles(root, inserts)
    top = pairs(root)
    all = []
    each_style(top["fonts"], nil) do |s, ext|
      all << style_info(s, ext, inserts)
    end
    Array(top["font_collections"]&.children).each do |coll|
      cp = pairs(coll)
      ext = File.extname(cp["filename"].value.to_s).delete(".").downcase
      each_style(cp["fonts"], ext) { |s, e| all << style_info(s, e, inserts) }
    end
    all.compact
  end

  def each_style(fonts, collection_ext, &block)
    Array(fonts&.children).each do |font|
      styles = pairs(font)["styles"]
      Array(styles&.children).each { |s| yield(s, collection_ext) }
    end
  end

  # Returns the style's format list (existing or newly planned) or nil.
  def style_info(style, collection_ext, inserts)
    sp = pairs(style)
    if sp["formats"]
      return sp["formats"].children.map(&:value)
    end

    file = sp["font"]&.value
    ext = collection_ext || File.extname(file.to_s).delete(".").downcase
    unless FORMATS.include?(ext)
      @ambiguous << "#{@path}: style #{sp['full_name']&.value.inspect} " \
                    "has unrecognised extension #{ext.inspect}"
      return nil
    end

    inserts << [insert_line(style), style.start_column, "formats", [ext]]
    @changes[:styles] += 1
    [ext]
  end

  def plan_resource(root, style_formats, inserts)
    resources = pairs(root)["resources"]
    return unless resources

    all = style_formats.flatten.uniq
    resources.children.each_slice(2) do |name, res|
      next if pairs(res)["format"]

      if all.size == 1 && style_formats.size == expected_styles(root)
        inserts << [insert_line(res), res.start_column, "format", all.first]
        @changes[:resources] += 1
      else
        @ambiguous << "#{@path}: resource #{name.value.inspect} left without " \
                      "format (style formats: #{all.inspect})"
      end
    end
  end

  def expected_styles(root)
    top = pairs(root)
    count = 0
    each_style(top["fonts"], nil) { count += 1 }
    Array(top["font_collections"]&.children).each do |coll|
      each_style(pairs(coll)["fonts"], nil) { count += 1 }
    end
    count
  end

  # Index in @lines after which new keys go: the last content line of the
  # mapping, i.e. before the first later line indented less than its keys.
  def insert_line(node)
    col = node.start_column
    last = node.start_line
    ((node.start_line + 1)...@lines.size).each do |i|
      line = @lines[i]
      next if line.strip.empty?
      break if line[/\A */].size < col

      last = i
    end
    last
  end

  def apply(inserts)
    inserts.sort_by { |i| -i[0] }.each do |line, col, key, value|
      pad = " " * col
      new = if value.is_a?(Array)
              ["#{pad}#{key}:\n"] + value.map { |v| "#{pad}- #{v}\n" }
            else
              ["#{pad}#{key}: #{value}\n"]
            end
      @lines.insert(line + 1, *new)
    end
  end
end

options = { dry_run: false, report: nil }
OptionParser.new do |o|
  o.on("--dry-run") { options[:dry_run] = true }
  o.on("--report FILE") { |f| options[:report] = f }
end.parse!

files = ARGV.flat_map do |a|
  File.directory?(a) ? Dir[File.join(a, "**", "*.yml")] : [a]
end.sort

totals = { files: 0, styles: 0, resources: 0 }
ambiguous = []
changed_files = []
files.each do |f|
  job = FormatBackfill.new(f)
  job.run
  ambiguous.concat(job.ambiguous)
  next unless job.changed?

  File.write(f, job.text) unless options[:dry_run]
  changed_files << f
  totals[:files] += 1
  totals[:styles] += job.changes[:styles]
  totals[:resources] += job.changes[:resources]
end

report = ["changed files: #{totals[:files]}",
          "styles given formats: #{totals[:styles]}",
          "resources given format: #{totals[:resources]}",
          "ambiguous / left alone: #{ambiguous.size}", *ambiguous]
puts report.first(4)
File.write(options[:report], "#{report.join("\n")}\n") if options[:report]
if options[:report]
  File.write("#{options[:report]}.changed",
             "#{changed_files.join("\n")}\n")
end
# rubocop:enable Metrics
