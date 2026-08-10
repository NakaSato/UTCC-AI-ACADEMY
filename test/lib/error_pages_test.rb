require "test_helper"

# The flat pages in public/ are generated from the same copy as the live ones,
# and nothing stops a translator editing the copy and leaving the files behind —
# nothing except this. They are the pages a visitor sees when the app is down,
# which is exactly when nobody is looking at them.
class ErrorPagesTest < ActiveSupport::TestCase
  test "the committed pages in public/ match the copy" do
    assert_empty ErrorPages.stale,
                 "Run bin/rails error_pages:build to rewrite them."
  end

  test "every static page exists" do
    HttpError::STATIC_PAGES.each_key do |filename|
      assert_predicate ErrorPages.path_for(filename), :exist?
    end
  end

  test "the browser gate points at a page that is there" do
    # ActionController's `allow_browser` renders this exact path, so its name is
    # not ours to change — see ApplicationController.
    assert_includes HttpError::STATIC_PAGES.keys, "406-unsupported-browser.html"
  end

  test "a static page carries both languages and needs nothing from the app" do
    html = ErrorPages.all.fetch("503.html")

    assert_includes html, I18n.t("error_pages.503.title", locale: :th)
    assert_includes html, I18n.t("error_pages.503.title", locale: :en)
    # No stylesheet, script or font the app would have to be running to serve.
    assert_no_match(/<link[^>]+stylesheet|<script/, html)
  end
end
