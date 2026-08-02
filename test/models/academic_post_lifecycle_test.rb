require "test_helper"

class AcademicPostLifecycleTest < ActiveSupport::TestCase
  test "students and instructors can own drafts but admins cannot" do
    assert_predicate AcademicPost.create!(owner: users(:one)), :draft?
    assert_predicate AcademicPost.create!(owner: users(:instructor)), :draft?

    post = AcademicPost.new(owner: users(:admin))
    assert_not post.valid?
    assert_predicate post.errors[:owner], :any?
  end

  test "saving a draft creates an immutable revision and increments its version" do
    post = AcademicPost.create!(owner: users(:one), title: "First", body: "Opening")
    post.revisions.create!(author: users(:one), version: post.lock_version,
                           title: post.title, body: post.body)

    post.save_draft!(author: users(:one), expected_lock_version: post.lock_version,
                     attributes: { title: "Updated", body: "A longer opening" })

    assert_equal 1, post.lock_version
    assert_equal "Updated", post.latest_revision.title
    assert_equal "A longer opening", post.latest_revision.body
    assert_equal 2, post.revisions.count
  end

  test "a stale draft save is rejected instead of overwriting a newer revision" do
    post = AcademicPost.create!(owner: users(:one), title: "First", body: "Opening")
    post.revisions.create!(author: users(:one), version: post.lock_version,
                           title: post.title, body: post.body)
    stale = AcademicPost.find(post.id)
    current = AcademicPost.find(post.id)

    current.save_draft!(author: users(:one), expected_lock_version: current.lock_version,
                        attributes: { title: "Current", body: "Newer content" })

    assert_raises ActiveRecord::StaleObjectError do
      stale.save_draft!(author: users(:one), expected_lock_version: stale.lock_version,
                        attributes: { title: "Stale", body: "Lost content" })
    end

    assert_equal "Current", post.class.find(post.id).title
    assert_equal 2, post.class.find(post.id).revisions.count
  end

  test "a draft is ready only when it has a title and body" do
    post = AcademicPost.new(owner: users(:one))
    assert_not_predicate post, :ready_for_review?

    post.assign_attributes(title: "A title", body: "A body")
    assert_predicate post, :ready_for_review?
  end
end
