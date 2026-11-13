require "rspec"
require_relative "../../../process/archive_fonts/liveness_checker"

RSpec.describe ArchiveFonts::LivenessChecker do
  describe "#check" do
    let(:checker) { described_class.new(rate_limit: 0, retries: 1, timeout: 2) }

    it "returns :alive for 200 response" do
      stub_request = instance_double(Net::HTTPResponse)
      allow(stub_request).to receive(:code).and_return("200")

      http_double = instance_double(Net::HTTP)
      allow(Net::HTTP).to receive(:new).and_return(http_double)
      allow(http_double).to receive(:use_ssl=)
      allow(http_double).to receive(:open_timeout=)
      allow(http_double).to receive(:read_timeout=)
      allow(http_double).to receive(:request).and_return(stub_request)

      expect(checker.check("https://example.com/font.zip")).to eq(:alive)
    end

    it "returns :alive for 301 redirect" do
      stub_request = instance_double(Net::HTTPResponse)
      allow(stub_request).to receive(:code).and_return("301")

      http_double = instance_double(Net::HTTP)
      allow(Net::HTTP).to receive(:new).and_return(http_double)
      allow(http_double).to receive(:use_ssl=)
      allow(http_double).to receive(:open_timeout=)
      allow(http_double).to receive(:read_timeout=)
      allow(http_double).to receive(:request).and_return(stub_request)

      expect(checker.check("https://example.com/font.zip")).to eq(:alive)
    end

    it "returns :dead for 404" do
      stub_request = instance_double(Net::HTTPResponse)
      allow(stub_request).to receive(:code).and_return("404")

      http_double = instance_double(Net::HTTP)
      allow(Net::HTTP).to receive(:new).and_return(http_double)
      allow(http_double).to receive(:use_ssl=)
      allow(http_double).to receive(:open_timeout=)
      allow(http_double).to receive(:read_timeout=)
      allow(http_double).to receive(:request).and_return(stub_request)

      expect(checker.check("https://example.com/font.zip")).to eq(:dead)
    end

    it "returns :dead for SocketError" do
      http_double = instance_double(Net::HTTP)
      allow(Net::HTTP).to receive(:new).and_return(http_double)
      allow(http_double).to receive(:use_ssl=)
      allow(http_double).to receive(:open_timeout=)
      allow(http_double).to receive(:read_timeout=)
      allow(http_double).to receive(:request).and_raise(SocketError)

      expect(checker.check("https://deadhost.example.com")).to eq(:dead)
    end

    it "returns :unknown for timeout" do
      http_double = instance_double(Net::HTTP)
      allow(Net::HTTP).to receive(:new).and_return(http_double)
      allow(http_double).to receive(:use_ssl=)
      allow(http_double).to receive(:open_timeout=)
      allow(http_double).to receive(:read_timeout=)
      allow(http_double).to receive(:request).and_raise(Net::OpenTimeout)

      expect(checker.check("https://slow.example.com")).to eq(:unknown)
    end

    it "returns :unknown for 500 server error" do
      stub_request = instance_double(Net::HTTPResponse)
      allow(stub_request).to receive(:code).and_return("500")

      http_double = instance_double(Net::HTTP)
      allow(Net::HTTP).to receive(:new).and_return(http_double)
      allow(http_double).to receive(:use_ssl=)
      allow(http_double).to receive(:open_timeout=)
      allow(http_double).to receive(:read_timeout=)
      allow(http_double).to receive(:request).and_return(stub_request)

      expect(checker.check("https://example.com")).to eq(:unknown)
    end
  end
end
