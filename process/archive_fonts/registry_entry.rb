# frozen_string_literal: true

module ArchiveFonts
  STATUSES = %w[archived pending failed not_archivable].freeze

  RegistryEntry = Struct.new(
    :url, :status, :archive_url, :original_alive,
    :last_checked, :formulas, keyword_init: true,
  ) do
    def initialize(original_alive: true, formulas: [], **args)
      super
    end

    def archived?
      status == "archived"
    end

    def alive?
      original_alive == true
    end

    def dead?
      original_alive == false
    end

    def to_h
      h = {
        "status" => status,
        "archive_url" => archive_url,
        "original_alive" => original_alive,
        "last_checked" => last_checked,
        "formulas" => formulas,
      }
      h.compact
    end

    def self.from_h(url, hash)
      new(
        url: url,
        status: hash["status"],
        archive_url: hash["archive_url"],
        original_alive: hash.fetch("original_alive", true),
        last_checked: hash["last_checked"],
        formulas: hash.fetch("formulas", []),
      )
    end
  end
end
