# frozen_string_literal: true

require "net/http"
require "uri"

module ArchiveFonts
  class LivenessChecker
    STATUSES = %i[alive dead unknown].freeze

    def initialize(rate_limit: 0.1, retries: 2, timeout: 10)
      @rate_limit = rate_limit
      @retries = retries
      @timeout = timeout
      @last_request = nil
    end

    def check(url)
      throttle

      attempts = 0
      begin
        uri = URI.parse(url)
        http = build_http(uri)
        request = Net::HTTP::Head.new(uri.request_uri, random_headers)
        response = http.request(request)
        categorize(response.code.to_i)
      rescue SocketError, Errno::ECONNREFUSED, Errno::ECONNRESET
        :dead
      rescue Net::OpenTimeout, Net::ReadTimeout, Timeout::Error
        attempts += 1
        retry if attempts < @retries
        :unknown
      rescue StandardError
        attempts += 1
        retry if attempts < @retries
        :unknown
      end
    end

    private

    def categorize(code)
      case code
      when 200..399 then :alive
      when 400..499 then :dead
      else :unknown
      end
    end

    def build_http(uri)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == "https"
      http.open_timeout = @timeout
      http.read_timeout = @timeout
      http
    end

    def throttle
      return unless @last_request

      elapsed = Time.now - @last_request
      sleep(@rate_limit - elapsed) if elapsed < @rate_limit
    ensure
      @last_request = Time.now
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
