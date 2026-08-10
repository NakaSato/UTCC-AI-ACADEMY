# The screens a failed request lands on. `config.exceptions_app` rewrites the
# path of anything that raised to its status code — /404, /500 — and dispatches
# it back through the router, which is why these routes answer every verb: a
# POST that blew up arrives here as a POST.
#
# It inherits ActionController::Base rather than ApplicationController on
# purpose. The error page is the one screen that has to render while the app is
# broken, and ApplicationController's callbacks would each give it a new way to
# fail: `require_authentication` reads the session out of the database, the
# header counts a learner's gems out of the database, and a 500 raised *by* the
# database would then raise again on the page reporting it. What survives that
# is a page that reads nothing.
class ErrorsController < ActionController::Base
  include Localization

  layout "error"

  # No `allow_browser` either — a browser too old for the app is still owed a
  # legible explanation of why it is seeing an error, and the layout here uses
  # nothing it would choke on.

  def show
    @error = HttpError.for(params[:code])

    # Never let an error page be cached: /500 is a description of one moment.
    expires_now

    if html_request?
      render :show, status: @error.code, formats: :html
    else
      head @error.code
    end
  end

  private
    # A request for a PDF, a Turbo Stream or JSON can fail too, and this page is
    # only meaningful as HTML. Everything else gets the bare status, which is
    # what Rails' default middleware did before this controller existed.
    #
    # `request.formats` parses the Accept header and raises on a malformed one —
    # which is itself a 400 that would arrive here, so it cannot be allowed to
    # raise a second time.
    def html_request?
      request.formats.any? { it.html? || it == Mime::ALL }
    rescue ActionController::BadRequest
      false
    end
end
