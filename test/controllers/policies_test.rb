require "test_helper"

# The privacy notice and the terms are the only screens a visitor has to be able
# to read *before* they have an account — sign-up asks them to accept both — so
# the tests that matter are that they are public, that every section resolves in
# both languages, and that the footer actually reaches them.
class PoliciesTest < ActionDispatch::IntegrationTest
  test "both documents are readable without an account" do
    sign_out

    [ privacy_path, terms_path ].each do |path|
      get path

      assert_response :success, path
      assert_select "main h1", 1, path
    end
  end

  test "every section renders its own heading and prose in both locales" do
    %w[th en].each do |locale|
      post language_path(locale)

      Policy.documents.each do |document|
        get document == :privacy ? privacy_path : terms_path

        assert_response :success
        # A missing key would render the fallback or the key itself rather than
        # raising, so the count is what catches a section added without copy.
        assert_select "main ol > li", Policy::SECTIONS.fetch(document).size
        refute_includes response.body, "translation missing"

        I18n.with_locale(locale) do
          assert_select "main h1", text: Policy.title_for(document)
          Policy.sections_for(document).each do |section|
            assert_includes response.body, section.title
            assert section.paragraphs.any?, "#{document}.#{section.key} has no body"
          end
        end
      end
    end
  end

  test "the footer reaches both documents from a signed-out page" do
    sign_out
    get root_path

    assert_select "footer a[href=?]", privacy_path, 1
    assert_select "footer a[href=?]", terms_path, 1
  end

  test "each document links to the other" do
    get privacy_path
    assert_select "main a[href=?]", terms_path, 1

    get terms_path
    assert_select "main a[href=?]", privacy_path, 1
  end

  test "a signed-in student can still read them" do
    sign_in_as users(:one)

    get privacy_path
    assert_response :success
  end
end
