# Rewrites Google formulas whose *_variable resources point at static API
# instances (fontist/fontist#435).
#
# The Google Fonts API only serves static per-weight files. The real variable
# TTFs live in github.com/google/fonts, listed in each family's METADATA.pb.
# For every formula with a ttf_variable/woff2_variable resource this script:
#   - moves the API files to ttf_static/woff2_static and marks their styles
#     non-variable;
#   - adds ttf_variable pointing at the variable TTFs, pinned to the clone's
#     commit, with axis tags from METADATA.pb, plus one variable style per file;
#   - never emits woff2_variable (Google publishes no variable woff2).
# A family with no variable file in the clone keeps only static resources and
# is listed in the report; nothing is guessed.
#
# Usage:
#   git clone --filter=blob:none --sparse --no-checkout \
#     https://github.com/google/fonts.git /tmp/gfonts
#   git -C /tmp/gfonts sparse-checkout set --no-cone \
#     '/ofl/*/METADATA.pb' '/apache/*/METADATA.pb' '/ufl/*/METADATA.pb'
#   git -C /tmp/gfonts checkout
#   ruby process/rewrite_google_variable_fonts.rb \
#     --gfonts /tmp/gfonts --fontist /path/to/fontist [--report report.md]
require "yaml"
require "optparse"

class RewriteGoogleVariableFonts
  def initialize(gfonts:, fontist:, formulas: "Formulas/google", report: nil)
    @gfonts = gfonts
    @formulas = formulas
    @report = report
    $LOAD_PATH.unshift(File.join(fontist, "lib"))
    require "fontist"
    require "fontist/import/google"
    @rewritten = []
    @unresolved = []
  end

  def call
    sources = variable_sources
    Dir.glob(File.join(@formulas, "*.yml")).sort.each do |path|
      process(path, sources)
    end
    write_report
    puts "rewritten: #{@rewritten.size}, unresolved: #{@unresolved.size}"
  end

  private

  def variable_sources
    families = Fontist::Import::Google::DataSources::Github
      .new(source_path: @gfonts).fetch
    families.to_h { |f| [f.family, f.variable_source] }
  end

  def process(path, sources)
    formula = YAML.safe_load_file(path)
    resources = formula["resources"] || {}
    return unless resources.key?("ttf_variable") ||
      resources.key?("woff2_variable")

    family = resources.values.first["family"]
    source = sources[family]
    @unresolved << [File.basename(path), family] unless source
    rewrite(formula, source, family)
    File.write(path, YAML.dump(formula))
    @rewritten << File.basename(path)
  end

  def rewrite(formula, source, family)
    formula["resources"] = rewrite_resources(formula["resources"], source,
                                             family)
    formula["fonts"] = rewrite_fonts(formula["fonts"], source)
  end

  def rewrite_resources(resources, source, family)
    result = {}
    result["ttf_variable"] = source.resource(family) if source
    static("ttf", resources).each { |k, v| result[k] = v }
    static("woff2", resources).each { |k, v| result[k] = v }
    result.merge(resources.reject { |k, _| k.match?(/_(variable|static)\z/) })
  end

  def static(format, resources)
    entry = resources["#{format}_variable"] || resources["#{format}_static"]
    return {} unless entry

    { "#{format}_static" => entry.reject { |k, _| k == "variable_axes" } }
  end

  def rewrite_fonts(fonts, source)
    (fonts || []).each do |font|
      font["styles"].each { |style| make_static(style, source) }
    end
    add_variable_styles(fonts || [], source)
  end

  def make_static(style, source)
    style["variable_font"] = false
    style.delete("variable_axes")
    style["source_resource"] = "ttf_static" if source
  end

  def add_variable_styles(fonts, source)
    return fonts unless source

    source.styles.group_by { |s| s["family_name"] }.each do |name, styles|
      entry = fonts.find { |f| f["name"] == name }
      entry ? entry["styles"].concat(styles) : fonts << { "name" => name,
                                                           "styles" => styles }
    end
    fonts
  end

  def write_report
    return unless @report

    lines = ["# Google variable font rewrite", "",
             "Rewritten formulas: #{@rewritten.size}", "",
             "## Unresolved (no variable file in google/fonts; demoted to " \
             "static, no variable resource emitted): #{@unresolved.size}", ""]
    @unresolved.each { |file, family| lines << "- #{file} (#{family})" }
    File.write(@report, "#{lines.join("\n")}\n")
  end
end

if $PROGRAM_NAME == __FILE__
  opts = { formulas: "Formulas/google" }
  OptionParser.new do |o|
    o.on("--gfonts DIR") { |v| opts[:gfonts] = v }
    o.on("--fontist DIR") { |v| opts[:fontist] = v }
    o.on("--formulas DIR") { |v| opts[:formulas] = v }
    o.on("--report FILE") { |v| opts[:report] = v }
  end.parse!
  RewriteGoogleVariableFonts.new(**opts).call
end
