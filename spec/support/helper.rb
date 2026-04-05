# frozen_string_literal: true

module Helper
  def get_fixture_path(name)
    File.expand_path("../fixtures/#{name}", __dir__)
  end
end
