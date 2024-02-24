require "json"
require "yaml"

class TestName
  FORMULAS_PATH = Dir.glob("Formulas").first

  def initialize
    @errors = []
  end

  def call
    changed_formulas_paths.each do |path|
      check_name(path)
    end

    print_errors
  end

  private

  def changed_formulas_paths
    JSON.parse(File.read("changed.json")).select do |file|
      file.start_with?("Formulas/")
    end
  end

  def check_name(path)
    puts "Checking #{path}..."
    name = fetch_name(path)

    puts "Name: #{name || 'unset'}"
    return unless name

    generated_key = generate_key(name)
    key = fetch_key(path)
    puts "Generated key and key from path:\n#{generated_key}\n#{key}\n"
    return if generated_key == key

    @errors << [path, name, generated_key, key]
  end

  def fetch_name(path)
    content = YAML.load_file(path)
    content["name"]
  end

  def generate_key(name)
    name.downcase.gsub(" ", "_")
  end

  def fetch_key(path)
    path.sub("#{FORMULAS_PATH}/", "").sub(".yml", "").split("/").last
  end

  def print_errors
    return if @errors.empty?

    puts "\nErrors:"
    @errors.each do |path, name, generated_key, key|
      puts "#{path}\n#{name}\n#{generated_key}\n#{key}\n\n"
    end

    raise "There are errors occured."
  end
end

TestName.new.call
