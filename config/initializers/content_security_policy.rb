# Be sure to restart your server when you modify this file.

# The application-wide content security policy.
# See the Securing Rails Applications Guide for more information:
# https://guides.rubyonrails.org/security.html#content-security-policy-header
#
# The value here is almost entirely in `script-src`. Everything else is defence
# in depth; `script-src :self` plus a nonce is the directive that turns an
# injected string into a blocked resource rather than into executing code.
Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self
    policy.object_src  :none

    # Nothing frames this app and nothing should. `:self` rather than `:none`
    # matches the `X-Frame-Options: SAMEORIGIN` Rails already sends, so the two
    # headers cannot disagree about the same question.
    policy.frame_ancestors :self

    # A `<base>` or a form posting off-site are the two quiet ways an injection
    # redirects a request without running any script of its own.
    policy.base_uri    :self
    policy.form_action :self

    # No nonce, no execution. importmap-rails already stamps its inline importmap
    # and module script with `request.content_security_policy_nonce`; the one tag
    # it does not reach is the JSON-LD in SchemaHelper#json_ld, which passes the
    # nonce by hand. There are no inline `on*` handlers anywhere in app/views.
    #
    # **Vite changes nothing here in production or test.** What it builds is an
    # ordinary file served from this origin with a nonce, because single-file
    # components are compiled at build time — the compiler is in the toolchain,
    # never in the browser, which is the whole reason ADR-0053 took Vite rather
    # than relaxing this line.
    #
    # Development is the exception, and only development: Vite’s HMR client
    # loads from its own dev server and evaluates the modules it pushes, which
    # needs `unsafe_eval` and that origin. A developer runs with a weaker policy
    # than production, which is a real cost, taken knowingly and bounded to the
    # one environment where nothing is served to anybody.
    policy.script_src(*[ :self, (:unsafe_eval if Rails.env.development?),
                         ("http://#{ViteRuby.config.host_with_port}" if Rails.env.development?) ].compact)

    # `unsafe_inline` here is unavoidable, and is the honest trade. Nineteen
    # `style="…"` attributes across ten templates carry progress-bar widths and
    # stagger delays computed in Ruby — a percentage cannot be expressed as a
    # utility class, so those are inline by necessity rather than by habit. CSP
    # has no nonce mechanism for style *attributes*, only for <style> elements,
    # so the alternative is not a stricter policy but a broken layout. The XSS
    # value of this header is in script-src regardless.
    policy.style_src   :self, :unsafe_inline, "https://fonts.googleapis.com"

    policy.font_src    :self, :data, "https://fonts.gstatic.com"

    # A theory block renders its image as a background-image, and that URL is
    # developer-written in LessonContent::BLOCKS rather than posted by anyone.
    # `:data` is for inline SVG.
    policy.img_src     :self, :data, :https

    # Two things reach back to our own origin and nothing reaches anywhere else:
    # the lesson's two graded steps, which POST a form and read the HTML back,
    # and the notification bell's Action Cable subscription. `:self` covers the
    # WebSocket as well as the fetch — CSP3 matches `ws://`/`wss://` on the page's
    # own origin against `'self'`, which is why there is no `wss://` entry here
    # and why there must not be a hardcoded host. Still no JSON either way.
    #
    # In development the list gains Vite’s dev server and its HMR websocket, for
    # the reason above and nowhere else.
    policy.connect_src(*[ :self, ("http://#{ViteRuby.config.host_with_port}" if Rails.env.development?),
                          ("ws://#{ViteRuby.config.host_with_port}" if Rails.env.development?) ].compact)
  end

  # Random per request, not `request.session.id`. The landing page is served to
  # visitors with no session at all, and a session-derived nonce is the empty
  # string for them — which would leave the inline importmap unsigned and break
  # every screen for exactly the audience least able to report it. The cost is
  # that HTML bodies stop being byte-identical between requests, so `Rack::ETag`
  # can no longer answer 304 for them; asset caching, which is what Thruster
  # actually handles, is untouched.
  config.content_security_policy_nonce_generator = ->(_request) { SecureRandom.base64(16) }
  config.content_security_policy_nonce_directives = %w[ script-src ]
end
