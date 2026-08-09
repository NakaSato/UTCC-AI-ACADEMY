require "test_helper"
require "yaml"

class DatabaseVersionTest < ActiveSupport::TestCase
  ROOT = Rails.root

  test "the development compose file pins the PostgreSQL 18 image" do
    image = YAML.load_file(ROOT.join("compose.yml")).dig("services", "postgres", "image")

    assert_equal "postgres:18-alpine", image
  end

  test "the connected server runs PostgreSQL 18 or newer" do
    version_num = ActiveRecord::Base.connection.select_value("SHOW server_version_num").to_i

    assert_operator version_num, :>=, 18_00_00
  end
end
