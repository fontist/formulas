require "rspec"
require "tmpdir"
require_relative "../../../process/archive_fonts/formula_updater"

RSpec.describe ArchiveFonts::FormulaUpdater do
  let(:dir) { Dir.mktmpdir }
  after { FileUtils.remove_entry(dir) }

  let(:formula_path) { File.join(dir, "test.yml") }

  let(:formula_content) do
    <<~YAML
      schema_version: 5
      name: Test
      resources:
        font.zip:
          urls:
          - https://example.com/font.zip
          sha256: abc123
      fonts:
      - name: Test
        styles:
        - family_name: Test
          type: Regular
          font: test.ttf
    YAML
  end

  before { File.write(formula_path, formula_content) }

  describe "#has_mirror?" do
    it "returns false when mirror not present" do
      expect(described_class.new.has_mirror?(formula_path, "https://web.archive.org/web/example")).to be false
    end

    it "returns true when mirror is present" do
      content = File.read(formula_path)
      content = content.sub("    - https://example.com/font.zip",
                            "    - https://example.com/font.zip\n    - https://web.archive.org/web/example")
      File.write(formula_path, content)

      expect(described_class.new.has_mirror?(formula_path, "https://web.archive.org/web/example")).to be true
    end
  end

  describe "#add_mirror" do
    it "appends mirror URL after original" do
      updater = described_class.new
      result = updater.add_mirror(formula_path, "https://example.com/font.zip",
                                  "https://web.archive.org/web/20260101/font.zip")
      expect(result).to be true

      content = File.read(formula_path)
      expect(content).to include("    - https://example.com/font.zip")
      expect(content).to include("    - https://web.archive.org/web/20260101/font.zip")

      lines = content.lines
      orig_idx = lines.index { |l| l.include?("https://example.com/font.zip") }
      mirror_idx = lines.index { |l| l.include?("web.archive.org/web/20260101") }
      expect(mirror_idx).to eq(orig_idx + 1)
    end

    it "does not add duplicate mirrors" do
      updater = described_class.new
      updater.add_mirror(formula_path, "https://example.com/font.zip",
                         "https://web.archive.org/web/20260101/font.zip")
      result = updater.add_mirror(formula_path, "https://example.com/font.zip",
                                  "https://web.archive.org/web/20260101/font.zip")
      expect(result).to be false
    end

    it "returns false when original URL not found" do
      updater = described_class.new
      result = updater.add_mirror(formula_path, "https://nonexistent.com/font.zip",
                                  "https://web.archive.org/web/example")
      expect(result).to be false
    end

    it "preserves rest of formula unchanged" do
      original = File.read(formula_path)
      described_class.new.add_mirror(formula_path, "https://example.com/font.zip",
                                     "https://web.archive.org/web/20260101/font.zip")

      updated = File.read(formula_path)
      # Everything before and after the mirror should be identical
      original_before_url = original.split("    - https://example.com/font.zip").first
      updated_before_url = updated.split("    - https://example.com/font.zip").first
      expect(updated_before_url).to eq(original_before_url)
    end
  end

  describe "#replace_with_mirror" do
    it "replaces dead original with archive mirror" do
      updater = described_class.new
      result = updater.replace_with_mirror(formula_path, "https://example.com/font.zip",
                                           "https://web.archive.org/web/20260101/font.zip")
      expect(result).to be true

      content = File.read(formula_path)
      expect(content).not_to include("https://example.com/font.zip")
      expect(content).to include("https://web.archive.org/web/20260101/font.zip")
    end

    it "removes original when mirror already present" do
      content = File.read(formula_path)
      content = content.sub("    - https://example.com/font.zip",
                            "    - https://example.com/font.zip\n    - https://web.archive.org/web/20260101/font.zip")
      File.write(formula_path, content)

      updater = described_class.new
      result = updater.replace_with_mirror(formula_path, "https://example.com/font.zip",
                                           "https://web.archive.org/web/20260101/font.zip")
      expect(result).to be true

      updated = File.read(formula_path)
      expect(updated).not_to include("https://example.com/font.zip")
      expect(updated).to include("https://web.archive.org/web/20260101/font.zip")
    end
  end
end
