require "test_helper"

# A CSP fails in two directions and neither is visible in a test that only asks
# whether the page rendered: too loose and it protects nothing, too tight and it
# silently drops a resource the page needs. Both are asserted here.
class ContentSecurityPolicyTest < ActionDispatch::IntegrationTest
  def policy
    response.headers["Content-Security-Policy"].to_s
  end

  def directive(name)
    policy.split(";").map(&:strip).find { it.start_with?("#{name} ") }.to_s
  end

  test "the landing page a stranger reads carries the policy" do
    get root_path

    assert_predicate policy, :present?
    assert_includes directive("script-src"), "'self'"
  end

  # The whole point of the header. `unsafe-inline` here would let an injected
  # <script> run and make the rest of this file decoration.
  test "script-src allows no inline execution and no remote origin" do
    get root_path

    assert_not_includes directive("script-src"), "unsafe-inline"
    assert_not_includes directive("script-src"), "unsafe-eval"
    assert_not_includes directive("script-src"), "https:"
  end

  test "the quiet redirection routes are closed" do
    get root_path

    assert_includes directive("base-uri"), "'self'"
    assert_includes directive("form-action"), "'self'"
    assert_includes directive("object-src"), "'none'"
  end

  # Google Fonts is a real dependency of the design — see shared/_fonts. If the
  # app ever self-hosts them, these two allowances should go with it.
  test "the font origins the design actually loads from are allowed" do
    get root_path

    assert_includes directive("style-src"), "https://fonts.googleapis.com"
    assert_includes directive("font-src"), "https://fonts.gstatic.com"
  end

  # Not an oversight — nineteen computed `style="width: …%"` attributes carry the
  # progress bars, and CSP has no nonce for style attributes. Asserted so the
  # allowance stays a decision rather than becoming a surprise.
  test "style-src permits inline attributes, deliberately" do
    get root_path

    assert_includes directive("style-src"), "unsafe-inline"
  end

  test "every inline script on a page carries a nonce the policy names" do
    get root_path

    nonce = response.body[/<meta name="csp-nonce" content="([^"]+)"/, 1]
    assert_predicate nonce, :present?, "csp_meta_tag should publish the nonce"
    assert_includes directive("script-src"), "'nonce-#{nonce}'"

    inline = response.body.scan(/<script(?![^>]*\bsrc=)([^>]*)>/).flatten
    assert_predicate inline, :any?, "the importmap and the JSON-LD are both inline"
    inline.each do |attributes|
      assert_includes attributes, "nonce=\"#{nonce}\"",
        "an inline <script> without the nonce is dropped by the policy: <script#{attributes}>"
    end
  end

  # The regression this guards is specific: json_ld builds its tag by hand, so
  # nonce_auto never reaches it, and a dropped JSON-LD block costs the site its
  # structured data without changing a pixel.
  test "the JSON-LD documents survive the policy on a page that publishes several" do
    get root_path

    documents = response.body.scan(/<script[^>]*application\/ld\+json[^>]*>/)
    assert_operator documents.size, :>=, 2, "the landing page publishes an organization plus its lists"
    documents.each { assert_includes it, "nonce=", "a JSON-LD tag with no nonce is a dropped document" }
  end

  test "a nonce is issued to a visitor with no session, not left blank" do
    get root_path
    anonymous = response.body[/<meta name="csp-nonce" content="([^"]+)"/, 1]

    assert_predicate anonymous, :present?,
      "a session-derived nonce would be empty here and would break the landing page"
  end

  test "the nonce differs between requests" do
    get root_path
    first = response.body[/<meta name="csp-nonce" content="([^"]+)"/, 1]
    get root_path
    second = response.body[/<meta name="csp-nonce" content="([^"]+)"/, 1]

    assert_not_equal first, second
  end

  test "signed-in screens carry the policy too, not just the public one" do
    sign_in_as users(:student)
    FeatureSetting.find_by!(key: "leaderboard").update!(enabled: true)

    [ my_learning_path, progress_path, lesson_path, leaderboard_path ].each do |path|
      get path

      assert_predicate policy, :present?, "#{path} should carry a CSP"
      assert_not_includes directive("script-src"), "unsafe-inline", "#{path} weakened script-src"
    end
  end
end
