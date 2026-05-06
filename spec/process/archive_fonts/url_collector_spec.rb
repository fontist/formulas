require "rspec"
require "yaml"
require "tmpdir"
require_relative "../../../process/archive_fonts/url_collector"

RSpec.describe ArchiveFonts::URLCollector do
  let(:dir) { Dir.mktmpdir }
  after { FileUtils.remove_entry(dir) }

  def write_formula(path, urls)
    data = {
      "resources" => {
        "font.zip" => {
          "urls" => urls,
          "sha256" => "abc123",
        },
      },
    }
    File.write(path, YAML.dump(data))
  end

  describe "#from_directory" do
    before do
      FileUtils.mkdir_p(File.join(dir, "google"))
      FileUtils.mkdir_p(File.join(dir, "sil"))

      write_formula(File.join(dir, "arial.yml"), ["https://example.com/arial.zip"])
      write_formula(File.join(dir, "google/google_font.yml"), ["https://fonts.gstatic.com/a.ttf"])
      write_formula(File.join(dir, "sil/sil_font.yml"), ["https://software.sil.org/download.zip"])
    end

    it "skips google formulas" do
      collector = described_class.new
      items = collector.from_directory(dir)
      urls = items.map { |i| i[:url] }
      expect(urls).not_to include("https://fonts.gstatic.com/a.ttf")
    end

    it "collects URLs from manual and sil formulas" do
      collector = described_class.new
      items = collector.from_directory(dir)
      urls = items.map { |i| i[:url] }
      expect(urls).to include("https://example.com/arial.zip")
      expect(urls).to include("https://software.sil.org/download.zip")
    end

    it "filters by group sil" do
      collector = described_class.new
      items = collector.from_directory(dir, group: "sil")
      urls = items.map { |i| i[:url] }
      expect(urls).to eq(["https://software.sil.org/download.zip"])
    end

    it "filters by group manual" do
      collector = described_class.new
      items = collector.from_directory(dir, group: "manual")
      urls = items.map { |i| i[:url] }
      expect(urls).to eq(["https://example.com/arial.zip"])
    end
  end

  describe "archive.org URL filtering" do
    it "skips URLs containing web.archive.org" do
      write_formula(File.join(dir, "test.yml"), [
        "https://example.com/font.zip",
        "https://web.archive.org/web/20260101/https://example.com/font.zip",
      ])

      collector = described_class.new
      items = collector.from_directory(dir)
      urls = items.map { |i| i[:url] }
      expect(urls).to eq(["https://example.com/font.zip"])
    end
  end

  describe "deduplication" do
    it "deduplicates URLs shared across formulas" do
      write_formula(File.join(dir, "a.yml"), ["https://shared.com/font.zip"])
      write_formula(File.join(dir, "b.yml"), ["https://shared.com/font.zip"])

      collector = described_class.new
      items = collector.from_directory(dir)
      expect(items.size).to eq(1)
      expect(items.first[:formulas]).to contain_exactly(
        File.join(dir, "a.yml"),
        File.join(dir, "b.yml"),
      )
    end
  end

  describe "resource_key tracking" do
    it "records the resource key for each URL" do
      write_formula(File.join(dir, "test.yml"), ["https://example.com/font.zip"])
      collector = described_class.new
      items = collector.from_directory(dir)
      expect(items.first[:resource_key]).to eq("font.zip")
    end
  end
end
