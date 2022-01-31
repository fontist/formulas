require "json"
require "yaml"
require "tmpdir"
require "optparse"
require "fontist"

class TestFormulas
  def initialize(args)
    OptionParser.new do |opts|
      opts.banner = "Usage: ruby test_formulas.rb [options]"

      opts.on("--every-platform", "Run formulas supported on every platform") do |every|
        @every_platform = every
      end

      opts.on("--platform PLATFORM", "Run formulas supported on PLATFORM") do |platform|
        @platform = platform
      end
    end.parse!

    @errors = []
  end

  def call
    prepare_formulas do |formulas|
      install(formulas)
    end

    print_errors
  end

  def prepare_formulas
    create_fontist_home do
      copy_formulas
      rebuild_index

      yield formulas_names
    end
  end

  def create_fontist_home
    Dir.mktmpdir do |dir|
      ENV["FONTIST_PATH"] = dir

      yield dir

      ENV["FONTIST_PATH"] = nil
    end
  end

  def copy_formulas
    formulas_paths.each do |formula|
      path = Fontist.formulas_repo_path.join(formula)
      dir = File.dirname(path)
      FileUtils.mkdir_p(dir)
      FileUtils.cp(formula, dir)
    end
  end

  def formulas_paths
    @formulas ||= JSON.parse(File.read("changed.json")).select do |file|
      next unless file.start_with?("Formulas/")

      content = YAML.load_file(file)
      downloadable?(content) && match_platform?(content)
    end
  end

  def downloadable?(content)
    !!content["resources"]
  end

  def match_platform?(content)
    return true if @every_platform && content["platforms"].nil?

    @platform && content["platforms"] && content["platforms"].any? do |p|
      p.start_with?(@platform)
    end
  end

  def rebuild_index
    Fontist::Index.rebuild
  end

  def formulas_names
    formulas_paths.map do |formula|
      formula.sub(/^Formulas\//, "").sub(/\.yml$/, "")
    end
  end

  def install(formulas)
    Fontist.log_level = :info

    puts "Formulas changed:"
    puts formulas

    puts "Installing.."
    formulas.each do |formula|
      puts "Formula: '#{formula}'."
      install_formula(formula)
    end
  end

  def install_formula(formula)
    Fontist::Font.install(
      formula,
      formula: true,
      force: true,
      confirmation: "yes",
      hide_licenses: true,
      no_progress: true,
    )
  rescue StandardError => e
    @errors << [e, formula]
  end

  def print_errors
    return if @errors.empty?

    @errors.each do |e, formula|
      puts "#{formula}, #{e}"
    end

    raise "There are errors occured."
  end
end

TestFormulas.new(ARGV.dup).call
