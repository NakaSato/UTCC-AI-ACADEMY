require "test_helper"

class AcademicPostsControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:one) }

  test "a student can render the new academic post form" do
    assert_equal "/academic", academic_posts_path
    get new_academic_post_path

    assert_response :success
    assert_select "#academic_post_body"
  end

  test "a student creates, reopens and updates a private draft" do
    get academic_posts_path
    assert_response :success

    assert_difference "AcademicPost.count", 1 do
      post academic_posts_path, params: {
        academic_post: { title: "My first paper", body: "The first paragraph" }
      }
    end

    created = AcademicPost.order(:id).last
    assert_equal users(:one), created.owner
    assert_equal "draft", created.status
    assert_redirected_to academic_post_path(created)

    get edit_academic_post_path(created)
    assert_response :success
    assert_select "form[action=?]", academic_post_path(created)
    assert_select "article"
    assert_includes response.body, "The first paragraph"

    patch academic_post_path(created), params: {
      academic_post: {
        title: "Reopened paper",
        body: "The revised paragraph",
        lock_version: created.lock_version
      }
    }

    assert_redirected_to academic_post_path(created)
    assert_equal "Reopened paper", created.reload.title
    assert_equal 2, created.revisions.count
  end

  test "a forged owner and status cannot turn a student draft into someone else's post" do
    assert_difference "AcademicPost.count", 1 do
      post academic_posts_path, params: {
        academic_post: {
          title: "Safe draft",
          body: "Content",
          owner_id: users(:two).id,
          status: "published"
        }
      }
    end

    created = AcademicPost.order(:id).last
    assert_equal users(:one), created.owner
    assert_predicate created, :draft?
  end

  test "a student cannot read another student's draft" do
    private_post = AcademicPost.create!(owner: users(:two), title: "Private", body: "Not yours")

    get academic_post_path(private_post)
    assert_response :not_found

    get export_academic_post_path(private_post)
    assert_response :not_found
  end

  test "a reader can export sanitized HTML and render reader controls" do
    academic_post = AcademicPost.create!(owner: users(:one), title: "Reader", body: "<h2>Methods</h2><span data-type='citation' data-citation-key='smith-2026'>[smith-2026]</span><p data-type='reference' data-reference-key='smith-2026'>[smith-2026] Safe source</p><script>alert(1)</script><p>Safe</p>")

    get academic_post_path(academic_post)
    assert_response :success
    assert_select "[data-controller=?]", "reader"
    assert_select "[data-reader-target=?]", "toc"
    assert_select "article[data-reader-target=surface]", 1
    assert_includes response.body, 'data-citation-key="smith-2026"'
    assert_includes response.body, 'data-reference-key="smith-2026"'

    get export_academic_post_path(academic_post)
    assert_response :success
    assert_equal "text/html", response.media_type
    assert_includes response.body, "Safe"
    assert_includes response.body, "smith-2026"
    assert_not_includes response.body, "<script>"
  end

  test "the owner submits a complete draft and an instructor publishes it" do
    academic_post = AcademicPost.create!(owner: users(:one), title: "Ready", body: "Complete")

    post submit_academic_post_path(academic_post)
    assert_redirected_to academic_post_path(academic_post)
    assert_predicate academic_post.reload, :review?

    sign_out
    sign_in_as users(:instructor)
    post publish_academic_post_path(academic_post)

    assert_redirected_to academic_post_path(academic_post)
    assert_predicate academic_post.reload, :published?
  end

  test "an incomplete draft cannot be submitted for review" do
    academic_post = AcademicPost.create!(owner: users(:one))

    post submit_academic_post_path(academic_post)

    assert_redirected_to academic_post_path(academic_post)
    assert_predicate academic_post.reload, :draft?
  end

  test "an owner can import a validated picture into a draft" do
    academic_post = AcademicPost.create!(owner: users(:one), title: "Pictures", body: "Draft")

    assert_difference "ActiveStorage::Attachment.count", 1 do
      post pictures_academic_post_path(academic_post), params: {
        picture: uploaded_picture,
        alt: "A diagram"
      }
    end

    assert_response :created
    payload = JSON.parse(response.body)
    assert_equal "A diagram", payload.fetch("alt")
    assert_match %r{\A/rails/active_storage/}, payload.fetch("url")
    assert_equal 1, academic_post.reload.pictures.count
  ensure
    @picture_tempfile&.close!
  end

  test "a picture import rejects unsafe content" do
    academic_post = AcademicPost.create!(owner: users(:one), title: "Pictures", body: "Draft")

    post pictures_academic_post_path(academic_post), params: {
      picture: uploaded_picture(content_type: "image/webp")
    }

    assert_response :unprocessable_entity
    assert_includes JSON.parse(response.body).fetch("errors"),
                    "The picture content does not match its declared type."
  ensure
    @picture_tempfile&.close!
  end

  private
    def uploaded_picture(content_type: "image/png")
      @picture_tempfile = Tempfile.new([ "academic-post-picture", ".png" ])
      @picture_tempfile.binmode
      @picture_tempfile.write("\x89PNG\r\n\x1A\n".b + ("\0" * 8) + [ 100, 100 ].pack("N2") + ("\0" * 32))
      @picture_tempfile.rewind
      Rack::Test::UploadedFile.new(
        @picture_tempfile.path,
        content_type,
        true,
        original_filename: "diagram.png"
      )
    end
end
