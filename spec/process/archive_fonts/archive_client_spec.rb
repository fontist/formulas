require "rspec"
require "json"
require_relative "../../../process/archive_fonts/archive_client"

RSpec.describe ArchiveFonts::ArchiveClient do
  let(:client) { described_class.new(rate_limit: 0) }

  describe "#check_availability" do
    it "returns archive URL when snapshot is available" do
      body = JSON.generate({
        "archived_snapshots" => {
          "closest" => {
            "available" => true,
            "url" => "https://web.archive.org/web/20260101/https://example.com/font.zip",
          },
        },
      })

      response = instance_double(Net::HTTPResponse)
      allow(response).to receive(:code).and_return("200")
      allow(response).to receive(:body).and_return(body)

      allow(client).to receive(:http_get).and_return(response)

      result = client.check_availability("https://example.com/font.zip")
      expect(result).to eq("https://web.archive.org/web/20260101/https://example.com/font.zip")
    end

    it "returns nil when no snapshot exists" do
      body = JSON.generate({
        "archived_snapshots" => { "closest" => nil },
      })

      response = instance_double(Net::HTTPResponse)
      allow(response).to receive(:code).and_return("200")
      allow(response).to receive(:body).and_return(body)

      allow(client).to receive(:http_get).and_return(response)

      expect(client.check_availability("https://example.com/new.zip")).to be_nil
    end

    it "returns nil on HTTP error" do
      allow(client).to receive(:http_get).and_return(nil)
      expect(client.check_availability("https://example.com")).to be_nil
    end
  end

  describe "#validate_snapshot" do
    it "returns true for 200 response" do
      response = instance_double(Net::HTTPResponse)
      allow(response).to receive(:code).and_return("200")
      allow(client).to receive(:http_head).and_return(response)

      expect(client.validate_snapshot("https://web.archive.org/web/example")).to be true
    end

    it "returns false for 404 response" do
      response = instance_double(Net::HTTPResponse)
      allow(response).to receive(:code).and_return("404")
      allow(client).to receive(:http_head).and_return(response)

      expect(client.validate_snapshot("https://web.archive.org/web/example")).to be false
    end

    it "returns false on error" do
      allow(client).to receive(:http_head).and_raise(StandardError)
      expect(client.validate_snapshot("https://web.archive.org/web/example")).to be false
    end
  end

  describe "#submit" do
    it "extracts archive URL from 302 Location header" do
      response = instance_double(Net::HTTPResponse)
      allow(response).to receive(:code).and_return("302")
      allow(response).to receive(:[]).with("Location").and_return("/web/20260101/https://example.com/font.zip")

      http_double = instance_double(Net::HTTP)
      allow(Net::HTTP).to receive(:new).and_return(http_double)
      allow(http_double).to receive(:use_ssl=)
      allow(http_double).to receive(:open_timeout=)
      allow(http_double).to receive(:read_timeout=)
      allow(http_double).to receive(:request).and_return(response)

      result = client.submit("https://example.com/font.zip")
      expect(result).to eq("https://web.archive.org/web/20260101/https://example.com/font.zip")
    end

    it "handles absolute Location URLs" do
      response = instance_double(Net::HTTPResponse)
      allow(response).to receive(:code).and_return("302")
      allow(response).to receive(:[]).with("Location").and_return("https://web.archive.org/web/20260101/font.zip")

      http_double = instance_double(Net::HTTP)
      allow(Net::HTTP).to receive(:new).and_return(http_double)
      allow(http_double).to receive(:use_ssl=)
      allow(http_double).to receive(:open_timeout=)
      allow(http_double).to receive(:read_timeout=)
      allow(http_double).to receive(:request).and_return(response)

      result = client.submit("https://example.com/font.zip")
      expect(result).to eq("https://web.archive.org/web/20260101/font.zip")
    end

    it "returns nil when no Location header" do
      response = instance_double(Net::HTTPResponse)
      allow(response).to receive(:code).and_return("302")
      allow(response).to receive(:[]).with("Location").and_return(nil)

      http_double = instance_double(Net::HTTP)
      allow(Net::HTTP).to receive(:new).and_return(http_double)
      allow(http_double).to receive(:use_ssl=)
      allow(http_double).to receive(:open_timeout=)
      allow(http_double).to receive(:read_timeout=)
      allow(http_double).to receive(:request).and_return(response)

      expect(client.submit("https://example.com/font.zip")).to be_nil
    end

    it "returns nil on unexpected HTTP code" do
      response = instance_double(Net::HTTPResponse)
      allow(response).to receive(:code).and_return("503")

      http_double = instance_double(Net::HTTP)
      allow(Net::HTTP).to receive(:new).and_return(http_double)
      allow(http_double).to receive(:use_ssl=)
      allow(http_double).to receive(:open_timeout=)
      allow(http_double).to receive(:read_timeout=)
      allow(http_double).to receive(:request).and_return(response)

      expect(client.submit("https://example.com/font.zip")).to be_nil
    end
  end
end
