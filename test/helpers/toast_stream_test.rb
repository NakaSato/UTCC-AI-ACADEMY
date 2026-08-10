require "test_helper"

# `turbo_stream.toast` is the server's way into the toast host. What it builds is
# a contract with app/javascript/toast_stream.js — the action name, the kind
# attribute, and the message sitting in the template as text — and every part of
# it is read out of the DOM by name, so a rename fails silently in the browser
# with nothing failing here. Hence the literal markup below.
class ToastStreamTest < ActionView::TestCase
  # Built against the test's view context rather than by including Turbo's
  # helper: that one hands the tag builder `self`, and the test case is not a
  # view — it has no `formats` for the builder to widen.
  def turbo_stream = Turbo::Streams::TagBuilder.new(view)

  test "it builds a toast stream tag addressed at the host" do
    assert_dom_equal %(<turbo-stream kind="info" action="toast" target="toasts"><template>Saved</template></turbo-stream>),
                     turbo_stream.toast("Saved")
  end

  test "the kind rides on the tag" do
    assert_dom_equal %(<turbo-stream kind="success" action="toast" target="toasts"><template>Saved</template></turbo-stream>),
                     turbo_stream.toast("Saved", kind: :success)
  end

  test "a kind the row has no variant for is a mistake, not a plain toast" do
    error = assert_raises(ArgumentError) { turbo_stream.toast("Saved", kind: :urgent) }

    assert_match "unknown toast kind :urgent", error.message
  end

  test "the four kinds the row has a variant for all build" do
    %i[ info success warning error ].each do |kind|
      assert_includes turbo_stream.toast("Saved", kind: kind), %(kind="#{kind}")
    end
  end

  test "a title and a duration ride as attributes" do
    tag = turbo_stream.toast("Saved", title: "All done", duration: 0)

    assert_includes tag, %(title="All done")
    assert_includes tag, %(duration="0")
  end

  # Omitted rather than zeroed: the controller's default is the default, and an
  # attribute saying "0" is a toast that never leaves.
  test "what is not given is not sent" do
    tag = turbo_stream.toast("Saved")

    assert_not_includes tag, "title="
    assert_not_includes tag, "duration="
    assert_not_includes tag, "action-"
  end

  test "an action rides as its three parts" do
    tag = turbo_stream.toast("Removed", action: { label: "Undo", href: "/undo", method: :post })

    assert_includes tag, %(action-label="Undo")
    assert_includes tag, %(action-href="/undo")
    assert_includes tag, %(action-method="post")
  end

  # A link with no href renders nothing, which looks like the toast simply not
  # offering the undo it was meant to.
  test "half an action is a mistake rather than a missing link" do
    error = assert_raises(ArgumentError) { turbo_stream.toast("Removed", action: { label: "Undo" }) }

    assert_match "needs both :label and :href", error.message
  end

  # The browser reads the message with textContent and writes it with
  # textContent, so this is belt and braces — but the message is the one part of
  # a toast that can be built from someone's own words, and the escaping is what
  # keeps the template from being a place to put markup.
  test "the message is escaped into the template rather than trusted as markup" do
    tag = turbo_stream.toast("<script>alert(1)</script>")

    assert_includes tag, "&lt;script&gt;alert(1)&lt;/script&gt;"
    assert_not_includes tag, "<script>"
  end

  test "it carries Thai unescaped, since only markup is the problem" do
    assert_includes turbo_stream.toast("บันทึกแล้ว"), "บันทึกแล้ว"
  end
end
