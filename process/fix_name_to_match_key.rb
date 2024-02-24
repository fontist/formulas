require "yaml"

class FixNameToMatchKey
  FORMULAS_PATH = Dir.glob("Formulas").first

  def initialize
    @no_name_list = []
    @equal_list = []
    @space_equal_list = []
    @case_sensitive_list = []
    @space_and_case_sensitive_list = []
    @custom_list = []
  end

  def call
    Dir.glob("Formulas/**/*.yml").each do |path|
      process(path)
    end

    print_results

    fix_name_attr
  end

  private

  def process(path)
    h = YAML.load_file(path)
    key = key(path)
    gen_name = name(key)
    unless h["name"]
      @no_name_list << [key, gen_name]
      return
    end

    choose_list(key, h["name"], gen_name)
  end

  def key(path)
    path.sub("#{FORMULAS_PATH}/", "").sub(".yml", "")
  end

  def name(key)
    last_part = key.downcase.gsub("_", " ").split("/").last
    last_part.split.map(&:capitalize).join(" ")
  end

  # rubocop:disable Metrics/MethodLength
  def choose_list(key, current_name, gen_name)
    if current_name == gen_name
      @equal_list << [key, current_name, gen_name]
    elsif current_name.gsub(" ", "") == gen_name.gsub(" ", "")
      @space_equal_list << [key, current_name, gen_name]
    elsif current_name.casecmp?(gen_name)
      @case_sensitive_list << [key, current_name, gen_name]
    elsif current_name.gsub(" ", "").casecmp?(gen_name.gsub(" ", ""))
      @space_and_case_sensitive_list << [key, current_name, gen_name]
    else
      @custom_list << [key, current_name, gen_name]
    end
  end
  # rubocop:enable Metrics/MethodLength

  def print_results
    print_size(@no_name_list, "No name")
    print_size(@equal_list, "Equal")
    print_size(@space_equal_list, "Space equal")
    print_list(@case_sensitive_list, "Case-sensitive")
    print_list(@space_and_case_sensitive_list, "Space and case-sensitive")
    print_list(@custom_list, "Custom")
  end

  def print_size(list, label)
    puts "#{label} list: #{list.size}"
    puts
  end

  def print_list(list, label)
    puts "#{label} list:"

    list.each do |key, name, gen_name|
      puts "#{key}: #{name} => #{gen_name}"
    end

    puts
  end

  def fix_name_attr
    restore_spaces(@space_and_case_sensitive_list)
    remove_name(@space_equal_list)
  end

  def restore_spaces(list)
    list.each do |key, name, gen_name|
      new_name = gen_with_spaces(name, gen_name)
      rewrite_name(key, new_name)
    end
  end

  def gen_with_spaces(name, gen_name)
    name.dup.tap do |n|
      space_indices = indices(gen_name, " ")
      space_indices.each do |index|
        n.insert(index, " ")
      end
    end
  end

  def indices(name, char)
    Array.new.tap do |indices|
      offset = 0
      while index = name.index(char, offset)
        indices << index
        offset = index + 1
      end
    end
  end

  def rewrite_name(key, name)
    rewrite_name_with_yaml(key, name)
  end

  def rewrite_name_with_yaml(key, name)
    path = File.join(FORMULAS_PATH, "#{key}.yml")
    h = YAML.load_file(path)
    h["name"] = name
    puts "Path: #{path}, #{YAML.dump(h).slice(0, 100)}"
    File.write(path, YAML.dump(h))
  end

  def remove_name(list)
    list.each do |key, _name, _gen_name|
      unset_name_and_save(key)
    end
  end

  def unset_name_and_save(key)
    path = File.join(FORMULAS_PATH, "#{key}.yml")
    h = YAML.load_file(path)
    h.delete("name")
    puts "Path: #{path}, #{YAML.dump(h).slice(0, 100)}"
    File.write(path, YAML.dump(h))
  end
end

FixNameToMatchKey.new.call
