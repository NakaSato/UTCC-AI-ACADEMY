require "test_helper"

class AcademicPostContentSafetyTest < ActiveSupport::TestCase
  test "sanitizes executable markup and unsafe picture sources" do
    sanitized = AcademicPostContentSanitizer.sanitize(<<~HTML)
      <p>Hello <strong>world</strong></p>
      <script>alert("xss")</script>
      <a href="javascript:alert(1)" onclick="alert(2)">bad link</a>
      <img src="data:image/png;base64,AAAA" onerror="alert(3)">
      <img src="/rails/active_storage/blobs/redirect/signed-id/photo.png" alt="A photo">
      <div data-type="inline-math" data-latex="E=mc^2"></div>
      <span data-type="citation" data-citation-key="smith-2026">[smith-2026]</span>
      <p data-type="reference" data-reference-key="smith-2026">[smith-2026] Safe source</p>
    HTML

    assert_includes sanitized, "<strong>world</strong>"
    assert_includes sanitized, "data-type=\"inline-math\""
    assert_includes sanitized, "data-latex=\"E=mc^2\""
    assert_includes sanitized, "/rails/active_storage/blobs/redirect/signed-id/photo.png"
    assert_includes sanitized, 'data-citation-key="smith-2026"'
    assert_includes sanitized, 'data-reference-key="smith-2026"'
    refute_includes sanitized, "script"
    refute_includes sanitized, "onclick"
    refute_includes sanitized, "javascript:"
    refute_includes sanitized, "data:image"
  end

  test "academic post persistence stores sanitized body" do
    post = AcademicPost.create!(
      owner: users(:one),
      title: "Safe post",
      body: '<p>Safe</p><script>alert("xss")</script>'
    )

    assert_includes post.reload.body, "<p>Safe</p>"
    refute_includes post.body, "<script>"
  end
end
