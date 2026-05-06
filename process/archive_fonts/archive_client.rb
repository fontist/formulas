# frozen_string_literal: true

require "net/http"
require "uri"
require "json"

module ArchiveFonts
  class ArchiveClient
    AVAILABILITY_URL = "https://archive.org/wayback/available"

    def initialize(rate_limit: 2, save_timeout: 120, availability_timeout: 15)
      @rate_limit = rate_limit
      @save_timeout = save_timeout
      @availability_timeout = availability_timeout
      @last_save = nil
    end

    def check_availability(url)
      api_url = "#{AVAILABILITY_URL}?url=#{URI.encode_www_form_component(url)}"
      response = http_get(api_url, timeout: @availability_timeout)
      return nil unless response&.code == "200"

      data = JSON.parse(response.body)
      snapshot = data.dig("archived_snapshots", "closest")
      return nil unless snapshot&.dig("available")

      snapshot["url"]
    rescue StandardError
      nil
    end

    def validate_snapshot(archived_url)
      response = http_head(archived_url, timeout: @availability_timeout)
      return false unless response

      code = response.code.to_i
      code >= 200 && code < 400
    rescue StandardError
      false
    end

    def submit(url)
      throttle_save

      save_url = "https://web.archive.org/save/#{url}"
      uri = URI.parse(save_url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.open_timeout = 30
      http.read_timeout = @save_timeout

      request = Net::HTTP::Get.new(uri.request_uri, random_headers)
      response = http.request(request)

      case response.code.to_i
      when 302
        extract_location(response)
      when 200
        extract_content_location(response)
      else
        nil
      end
    rescue StandardError
      nil
    end

    private

    def extract_location(response)
      location = response["Location"]
      return nil unless location

      location.start_with?("http") ? location : "https://web.archive.org#{location}"
    end

    def extract_content_location(response)
      cl = response["Content-Location"]
      return nil unless cl

      cl.start_with?("http") ? cl : "https://web.archive.org#{cl}"
    end

    def throttle_save
      return unless @last_save

      elapsed = Time.now - @last_save
      sleep(@rate_limit - elapsed) if elapsed < @rate_limit
    ensure
      @last_save = Time.now
    end

    def http_get(url, timeout: 15)
      uri = URI.parse(url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == "https"
      http.open_timeout = timeout
      http.read_timeout = timeout

      request = Net::HTTP::Get.new(uri.request_uri, random_headers)
      http.request(request)
    end

    def http_head(url, timeout: 15)
      uri = URI.parse(url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == "https"
      http.open_timeout = timeout
      http.read_timeout = timeout

      request = Net::HTTP::Head.new(uri.request_uri, random_headers)
      http.request(request)
    end

    def random_headers
      { "User-Agent" => USER_AGENTS.sample }
    end

    USER_AGENTS = [
      "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 " \
      "(KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36",
      "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 " \
      "(KHTML, like Gecko) Chrome/130.0.0.0 Safari/537.36",
      "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 " \
      "(KHTML, like Gecko) Chrome/132.0.0.0 Safari/537.36",
    ].freeze
  end
end
