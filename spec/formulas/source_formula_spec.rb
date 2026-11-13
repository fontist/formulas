# frozen_string_literal: true

require "yaml"

RSpec.describe "Formulas/source.yml" do
  let(:path) { File.expand_path("../../Formulas/source.yml", __dir__) }
  let(:formula) { YAML.safe_load_file(path) }
  let(:collections) { formula["font_collections"] }

  let(:han_sans_names) do
    regions = ["", " HC", " K", " SC", " TC"]
    weights = ["", " ExtraLight", " Light", " Normal", " Medium", " Heavy"]
    regions.product(weights).map { |r, w| "Source Han Sans#{r}#{w}" }
  end

  let(:latin_families) { ["Source Sans Pro", "Source Serif Pro", "Source Code Pro"] }

  let(:latin_weight_names) do
    latin_families.flat_map do |f|
      # Source Sans/Serif Pro never shipped a Medium cut; Code Pro did.
      weights = f == "Source Code Pro" ? %w[Black ExtraLight Light Medium Semibold] : %w[Black ExtraLight Light Semibold]
      weights.map { |w| "#{f} #{w}" }
    end
  end

  def styles_of(name)
    (collections.flat_map { |c| c["fonts"] } + Array(formula["fonts"]))
      .select { |f| f["name"] == name }
      .flat_map { |f| f["styles"] }
  end

  it "has a resource with urls, sha256 and file_size" do
    resource = formula["resources"].values.first
    expect(resource["urls"]).to be_a(Array).and(satisfy { |u| !u.empty? })
    expect(resource["sha256"]).to match(/\A\h{64}\z/)
    expect(resource["file_size"]).to be_a(Integer).and(be > 0)
  end

  it "provides every Source Han Sans font name" do
    names = collections.flat_map { |c| c["fonts"].map { |f| f["name"] } }
    expect(names).to include(*han_sans_names)
  end

  it "provides Regular and Bold for the base and regional families" do
    ["Source Han Sans", "Source Han Sans HC", "Source Han Sans K",
     "Source Han Sans SC", "Source Han Sans TC"].each do |name|
      expect(styles_of(name).map { |s| s["type"] })
        .to contain_exactly("Bold", "Regular")
    end
  end

  it "provides Regular for each weight variant" do
    variants = han_sans_names.grep(/ (ExtraLight|Light|Normal|Medium|Heavy)\z/)
    variants.each do |name|
      expect(styles_of(name).map { |s| s["type"] }).to eq(["Regular"])
    end
  end

  it "gives every collection style a post_script_name and version" do
    collections.flat_map { |c| c["fonts"] }.each do |font|
      font["styles"].each do |style|
        expect(style["post_script_name"]).not_to be_nil, font["name"]
        expect(style["version"]).not_to be_nil, font["name"]
      end
    end
  end

  it "provides every legacy Latin font name" do
    names = Array(formula["fonts"]).map { |f| f["name"] }
    expect(names).to include(*latin_families, *latin_weight_names)
  end

  it "provides Regular, Bold, Italic and Bold Italic for the Latin families" do
    latin_families.each do |name|
      expect(styles_of(name).map { |s| s["type"] })
        .to contain_exactly("Regular", "Bold", "Italic", "Bold Italic")
    end
  end

  it "provides Regular and Italic for each Latin weight variant" do
    latin_weight_names.each do |name|
      expect(styles_of(name).map { |s| s["type"] }).to contain_exactly("Regular", "Italic")
    end
  end

  it "gives every fonts entry a font file" do
    formula["fonts"].each do |font|
      font["styles"].each do |style|
        expect(style["font"]).to match(/\.(ttf|otf|ttc)\z/), font["name"]
        expect(style["post_script_name"]).not_to be_nil, font["name"]
        expect(style["version"]).not_to be_nil, font["name"]
      end
    end
  end
end
