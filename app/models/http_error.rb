# The error screens, as data. A request that fails is re-dispatched by
# `exceptions_app` to /404, /500 and the rest (see config/routes.rb), and this
# is what those paths know: which statuses are worth their own words, and what
# every other status falls back to.
#
# Ruby holds only the shape; every word is in the locale files under
# `error_pages`, the same split as Policy.
module HttpError
  # The statuses with copy of their own. Anything else in 4xx or 5xx still
  # renders a page — it borrows its family's words — because a status nobody
  # enumerated is exactly the one a visitor should not meet as a blank screen.
  NAMED = [ 400, 403, 404, 406, 422, 429, 500, 502, 503, 504 ].freeze

  # What a status falls back to when the path it arrived on is not one Rails
  # would ever produce.
  FALLBACK = 500

  # The pages that also exist as flat files in public/. Rails serves these when
  # a request fails before a controller can run, and a proxy serves them when
  # there is no app left to ask — which is the whole reason 502, 503 and 504 are
  # here at all: the app cannot be the thing that reports its own absence.
  # `bin/rails error_pages:build` writes them from the copy below.
  #
  # The browser file's name is Rails': `allow_browser` renders that exact path.
  STATIC_PAGES = {
    "400.html" => 400,
    "404.html" => 404,
    "422.html" => 422,
    "500.html" => 500,
    "502.html" => 502,
    "503.html" => 503,
    "504.html" => 504,
    "406-unsupported-browser.html" => 406
  }.freeze

  Page = Data.define(:code) do
    # The short status name beside the number — "Not found".
    def name = copy("name")

    def title = copy("title")

    def body = copy("body")

    # A 5xx is ours and a visitor can do nothing about it but wait; a 4xx is
    # usually one wrong address away from working. The two get different offers.
    def server? = code >= 500

    def client? = !server?

    def retry? = server?

    private
      # A code with no copy of its own reads its family's. `default:` given a
      # Symbol is another key to try, which is what makes the fallback a lookup
      # rather than a literal string.
      def copy(leaf)
        I18n.t("error_pages.#{code}.#{leaf}", default: :"error_pages.#{family}.#{leaf}")
      end

      def family = server? ? "server" : "client"
  end

  class << self
    def for(code)
      number = code.to_i

      Page.new(code: (400..599).cover?(number) ? number : FALLBACK)
    end

    def named = NAMED.map { Page.new(code: it) }

    def static_pages = STATIC_PAGES.transform_values { Page.new(code: it) }
  end
end
