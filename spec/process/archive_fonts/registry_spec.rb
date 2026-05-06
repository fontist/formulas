require "rspec"
require "yaml"
require "tmpdir"
require_relative "../../../process/archive_fonts/registry"
require_relative "../../../process/archive_fonts/registry_entry"

RSpec.describe ArchiveFonts::Registry do
  let(:dir) { Dir.mktmpdir }
  let(:path) { File.join(dir, "test_registry.yml") }

  after { FileUtils.remove_entry(dir) }

  subject(:registry) { described_class.load(path) }

  describe ".load" do
    it "creates empty registry when file doesn't exist" do
      expect(registry.entries).to be_empty
    end

    it "loads entries from existing file" do
      data = {
        "_metadata" => { "total" => 1 },
        "entries" => {
          "https://example.com/font.zip" => {
            "status" => "archived",
            "archive_url" => "https://web.archive.org/web/example",
            "original_alive" => true,
            "last_checked" => "2026-01-01T00:00:00Z",
            "formulas" => ["Formulas/test.yml"],
          },
        },
      }
      File.write(path, YAML.dump(data))

      reg = described_class.load(path)
      expect(reg.entries.size).to eq(1)

      entry = reg.find("https://example.com/font.zip")
      expect(entry).not_to be_nil
      expect(entry.status).to eq("archived")
      expect(entry.archive_url).to eq("https://web.archive.org/web/example")
    end
  end

  describe "#find" do
    it "returns nil for unknown URLs" do
      expect(registry.find("https://unknown.com")).to be_nil
    end
  end

  describe "#upsert" do
    it "adds a new entry" do
      entry = ArchiveFonts::RegistryEntry.new(
        url: "https://example.com/font.zip",
        status: "pending",
        formulas: ["Formulas/a.yml"],
      )
      registry.upsert(entry)
      expect(registry.find("https://example.com/font.zip")).to eq(entry)
    end

    it "merges formulas when upserting existing entry" do
      entry1 = ArchiveFonts::RegistryEntry.new(
        url: "https://example.com/font.zip",
        status: "pending",
        formulas: ["Formulas/a.yml"],
      )
      entry2 = ArchiveFonts::RegistryEntry.new(
        url: "https://example.com/font.zip",
        status: "pending",
        formulas: ["Formulas/b.yml"],
      )

      registry.upsert(entry1)
      registry.upsert(entry2)

      found = registry.find("https://example.com/font.zip")
      expect(found.formulas).to contain_exactly("Formulas/a.yml", "Formulas/b.yml")
    end
  end

  describe "#needs_processing?" do
    it "returns true for unknown URLs" do
      expect(registry.needs_processing?("https://unknown.com")).to be true
    end

    it "returns true for pending status" do
      registry.upsert(ArchiveFonts::RegistryEntry.new(
        url: "https://example.com", status: "pending",
      ))
      expect(registry.needs_processing?("https://example.com")).to be true
    end

    it "returns true for failed status" do
      registry.upsert(ArchiveFonts::RegistryEntry.new(
        url: "https://example.com", status: "failed",
      ))
      expect(registry.needs_processing?("https://example.com")).to be true
    end

    it "returns false for archived status" do
      registry.upsert(ArchiveFonts::RegistryEntry.new(
        url: "https://example.com", status: "archived",
      ))
      expect(registry.needs_processing?("https://example.com")).to be false
    end

    it "returns false for not_archivable status" do
      registry.upsert(ArchiveFonts::RegistryEntry.new(
        url: "https://example.com", status: "not_archivable",
      ))
      expect(registry.needs_processing?("https://example.com")).to be false
    end
  end

  describe "#save" do
    it "persists entries to YAML file" do
      entry = ArchiveFonts::RegistryEntry.new(
        url: "https://example.com/font.zip",
        status: "archived",
        archive_url: "https://web.archive.org/web/example",
        original_alive: true,
        last_checked: "2026-01-01T00:00:00Z",
        formulas: ["Formulas/test.yml"],
      )
      registry.upsert(entry)
      registry.save

      reloaded = described_class.load(path)
      found = reloaded.find("https://example.com/font.zip")
      expect(found.status).to eq("archived")
      expect(found.archive_url).to eq("https://web.archive.org/web/example")
    end

    it "includes metadata" do
      registry.save

      data = YAML.load_file(path)
      expect(data["_metadata"]).to include("last_sync", "total")
      expect(data["_metadata"]["total"]).to eq(0)
    end
  end

  describe "#count_by_status" do
    it "counts entries by status" do
      registry.upsert(ArchiveFonts::RegistryEntry.new(url: "a", status: "archived"))
      registry.upsert(ArchiveFonts::RegistryEntry.new(url: "b", status: "archived"))
      registry.upsert(ArchiveFonts::RegistryEntry.new(url: "c", status: "failed"))

      counts = registry.count_by_status
      expect(counts["archived"]).to eq(2)
      expect(counts["failed"]).to eq(1)
    end
  end
end
