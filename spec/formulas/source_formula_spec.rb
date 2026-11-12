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

  def styles_of(name)
    collections.flat_map { |c| c["fonts"] }
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
