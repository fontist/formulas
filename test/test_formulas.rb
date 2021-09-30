require "json"
require "yaml"
require "tmpdir"
require "fontist"

class TestFormulas
  def call
    prepare_formulas do |fonts_by_formula|
      install(fonts_by_formula)
    end
  end

  def install(fonts_by_formula)
    puts "Formulas changed:"
    puts fonts_by_formula.keys

    puts "Installing.."
    fonts_by_formula.each do |formula, font|
      puts "Formula: '#{formula}', font: '#{font}'."
      install_font(font)
    end
  end

  def install_font(font)
    Fontist::Font.install(
      font,
      force: true,
      confirmation: "yes",
      hide_licenses: true,
      no_progress: true,
    )
  end

  def prepare_formulas
    create_fontist_home do
      copy_formulas
      rebuild_index

      yield fonts_by_formula
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
    formulas.each do |formula|
      path = Fontist.formulas_repo_path.join(formula)
      dir = File.dirname(path)
      FileUtils.mkdir_p(dir)
      FileUtils.cp(formula, dir)
    end
  end

  def formulas
    @formulas ||= JSON.parse(File.read("changed.json")).select do |file|
      file.start_with?("Formulas/") && downloadable?(file)
    end
  end

  def downloadable?(file)
    !!YAML.load_file(file)["resources"]
  end

  def rebuild_index
    Fontist::Index.rebuild
  end

  def fonts_by_formula
    fonts = formulas.map do |file|
      data = YAML.load_file(file)
      font_from_formula(data)
    end

    formulas.zip(fonts).to_h
  end

  def font_from_formula(data)
    data.dig("fonts", 0, "name") ||
      data.dig("font_collections", 0, "fonts", 0, "name")
  end
end

TestFormulas.new.call
