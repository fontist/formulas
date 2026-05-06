require "rspec"
require_relative "../../../process/archive_fonts/registry_entry"

RSpec.describe ArchiveFonts::RegistryEntry do
  let(:attrs) do
    {
      url: "https://example.com/font.zip",
      status: "archived",
      archive_url: "https://web.archive.org/web/20260101/https://example.com/font.zip",
      original_alive: true,
      last_checked: "2026-05-05T10:00:00Z",
      formulas: ["Formulas/example.yml"],
    }
  end

  subject(:entry) { described_class.new(**attrs) }

  describe "#archived?" do
    it "returns true when status is archived" do
      expect(entry.archived?).to be true
    end

    it "returns false when status is failed" do
      entry.status = "failed"
      expect(entry.archived?).to be false
    end
  end

  describe "#alive?" do
    it "returns true when original_alive is true" do
      expect(entry.alive?).to be true
    end

    it "returns false when original_alive is false" do
      entry.original_alive = false
      expect(entry.alive?).to be false
    end
  end

  describe "#dead?" do
    it "returns true when original_alive is false" do
      entry.original_alive = false
      expect(entry.dead?).to be true
    end

    it "returns false when original_alive is true" do
      expect(entry.dead?).to be false
    end
  end

  describe "#to_h" do
    it "returns a hash with string keys" do
      h = entry.to_h
      expect(h).to be_a(Hash)
      expect(h.keys).to all(be_a(String))
      expect(h).to include("status", "archive_url", "original_alive")
    end

    it "omits nil values" do
      entry.archive_url = nil
      h = entry.to_h
      expect(h).not_to have_key("archive_url")
    end
  end

  describe ".from_h" do
    it "round-trips through to_h" do
      h = entry.to_h
      restored = described_class.from_h(entry.url, h)
      expect(restored.url).to eq(entry.url)
      expect(restored.status).to eq(entry.status)
      expect(restored.archive_url).to eq(entry.archive_url)
      expect(restored.original_alive).to eq(entry.original_alive)
      expect(restored.formulas).to eq(entry.formulas)
    end

    it "defaults original_alive to true when missing" do
      restored = described_class.from_h("http://x.com", { "status" => "pending" })
      expect(restored.original_alive).to be true
    end

    it "defaults formulas to empty array when missing" do
      restored = described_class.from_h("http://x.com", { "status" => "pending" })
      expect(restored.formulas).to eq([])
    end
  end
end
