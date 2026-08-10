require "test_helper"

# HttpError is what decides that a status nobody wrote copy for still has words.
# These tests guard that fallback in both directions: a named status keeps its
# own copy, and an unnamed one borrows its family's rather than raising a
# missing-translation error onto an error page.
class HttpErrorTest < ActiveSupport::TestCase
  test "a named status uses its own copy" do
    I18n.with_locale(:en) do
      assert_equal "Not found", HttpError.for(404).name
      assert_equal "There is nothing at this address", HttpError.for(404).title
    end
  end

  test "an unnamed status borrows its family's copy" do
    I18n.with_locale(:en) do
      assert_equal "Request error", HttpError.for(409).name
      assert_equal "Server error", HttpError.for(507).name
    end
  end

  test "every named status has copy of its own in both locales" do
    I18n.available_locales.each do |locale|
      I18n.with_locale(locale) do
        HttpError.named.each do |page|
          %w[name title body].each do |leaf|
            assert I18n.exists?("error_pages.#{page.code}.#{leaf}", locale),
                   "#{locale} is missing error_pages.#{page.code}.#{leaf}"
          end
        end
      end
    end
  end

  test "the family split follows the status class" do
    assert_predicate HttpError.for(404), :client?
    assert_not_predicate HttpError.for(404), :server?
    assert_predicate HttpError.for(503), :server?
    assert_predicate HttpError.for(503), :retry?
  end

  test "a status outside the error range falls back rather than rendering itself" do
    assert_equal HttpError::FALLBACK, HttpError.for(200).code
    assert_equal HttpError::FALLBACK, HttpError.for("banana").code
  end

  test "the codes are taken as given inside the error range" do
    assert_equal 418, HttpError.for("418").code
  end
end
