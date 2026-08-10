require "test_helper"

# The error screens. Two things are being guarded here and they pull in
# different directions: the page has to be a real page — branded, bilingual,
# answering the right status — and it has to render while the app is broken, so
# it must not depend on a session, a database read, or an acceptable format.
#
# The pages are exercised at /errors/:code rather than at /404, because the flat
# files in public/ shadow the bare paths whenever the static file server is on.
# What reaches the bare paths is `exceptions_app`, and that dispatch has a test
# of its own at the bottom.
class ErrorsTest < ActionDispatch::IntegrationTest
  test "every named status renders its own page at its own path" do
    HttpError::NAMED.each do |code|
      get "/errors/#{code}"

      assert_response code
      assert_select "h1", I18n.t("error_pages.#{code}.title", locale: :th)
    end
  end

  test "an unnamed error status still renders, using its family's copy" do
    get "/errors/409"

    assert_response :conflict
    assert_select "h1", I18n.t("error_pages.client.title", locale: :th)
  end

  test "a three-digit path that is not an error status is not an error page" do
    get "/errors/700"

    # A routing error, not a rendered 700 — the constraint keeps the route an
    # error route rather than a catch-all that will answer to any number.
    assert_response :not_found
    assert_no_match(/#{Regexp.escape(I18n.t("error_pages.client.title", locale: :th))}/, response.body)
  end

  test "the page follows the requested language" do
    get "/errors/404", params: { lang: "en" }

    assert_select "h1", I18n.t("error_pages.404.title", locale: :en)
  end

  test "the page is never indexed and never cached" do
    get "/errors/404"

    assert_select "meta[name=robots][content=?]", "noindex, nofollow"
    assert_match(/no-cache/, response.headers["Cache-Control"])
  end

  test "a server error offers the request id support would need" do
    get "/errors/500"

    assert_response :internal_server_error
    assert_select "main", text: /#{Regexp.escape(response.request.request_id)}/
  end

  test "a client error does not carry a request id" do
    get "/errors/404"

    assert_select "main", text: /#{Regexp.escape(I18n.t("error_pages.request_id", locale: :th))}/, count: 0
  end

  test "a failed request for something other than HTML gets the status and no page" do
    get "/errors/500", as: :json

    assert_response :internal_server_error
    assert_empty response.body
  end

  test "it answers whatever verb the failed request arrived on" do
    # Not through /errors/:code — that route is a GET. `exceptions_app` re-issues
    # the original request, so a POST that raised arrives at /422 as a POST.
    with_rendered_exceptions { post "/422" }

    assert_response :unprocessable_entity
  end

  test "the page reads nothing that a broken app would have broken" do
    # No session, and no query against the tables the application layout reads —
    # a 500 raised by the database must not raise again on the page reporting it.
    assert_no_queries { get "/errors/500" }

    assert_response :internal_server_error
  end

  test "a request for a route that does not exist lands on the branded page" do
    with_rendered_exceptions { get "/nothing-is-here" }

    assert_response :not_found
    assert_select "h1", I18n.t("error_pages.404.title", locale: :th)
  end

  private
    # Test runs show the debug page instead of the error page, which is what
    # makes a failing test readable. These two tests want the opposite: they are
    # about what production does with a failure, so they ask for production's
    # handling for the length of the block.
    def with_rendered_exceptions
      config = Rails.application.env_config
      original = config.values_at("action_dispatch.show_exceptions", "action_dispatch.show_detailed_exceptions")
      config["action_dispatch.show_exceptions"] = :all
      config["action_dispatch.show_detailed_exceptions"] = false

      yield
    ensure
      config["action_dispatch.show_exceptions"], config["action_dispatch.show_detailed_exceptions"] = original
    end
end
