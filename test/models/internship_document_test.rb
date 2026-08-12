require "test_helper"

# ADR-0041 decision 5, answered 2026-08-12: a request shares the résumé that
# already exists rather than storing a second one, a placement carries the
# student's deliverables, and both close when the thing they belong to closes.
class InternshipDocumentTest < ActiveSupport::TestCase
  setup do
    @organization = Organization.create!(name: "Document Org", creator: users(:admin),
                                         accepts_internship_requests: true)
    @decider = users(:one)
    @organization.memberships.create!(user: @decider, role: "owner")
    @student = users(:student)
    @profile = CandidateProfile.create!(user: @student, application_data_reuse_consent: true)
    attach_resume
    Current.session = @student.sessions.create!
  end

  teardown { Current.session = nil }

  # ---- The shared résumé ----------------------------------------------------

  test "sharing records a choice and stores no second copy of the file" do
    request = submitted_request

    assert_difference -> { ActiveStorage::Blob.count }, 0 do
      request.share_resume!(actor: @student)
    end

    assert_predicate request, :resume_shared?
    assert_equal @profile.resume.blob, request.shareable_resume.blob
  end

  test "only the student shares their own résumé, and only while the request is open" do
    request = submitted_request

    [ @decider, users(:admin), users(:two) ].each do |actor|
      assert_raises(ActiveRecord::RecordInvalid) { request.share_resume!(actor:) }
    end

    request.reject!(actor: @decider, reason: "Not this term")
    assert_raises(ActiveRecord::RecordInvalid) { request.share_resume!(actor: @student) }
  end

  test "a student with no résumé on their profile cannot share one" do
    @profile.reload.resume.purge
    request = submitted_request

    assert_raises(ActiveRecord::RecordInvalid) { request.share_resume!(actor: @student) }
    assert_not request.reload.resume_shared?
  end

  test "the company reads it while deciding, and never after a rejection" do
    request = submitted_request
    request.share_resume!(actor: @student)

    assert request.resume_readable_by?(@decider)
    assert request.resume_readable_by?(@student)

    request.reject!(actor: @decider, reason: "Not this term")
    assert_not request.reload.resume_readable_by?(@decider),
               "a company does not keep a résumé because it once considered someone"
    assert request.resume_readable_by?(@student), "the student always reads their own"
  end

  test "an approved request keeps it readable while the internship runs, and not after" do
    request = submitted_request
    request.share_resume!(actor: @student)
    request.approve!(actor: @decider)

    placement = InternshipPlacement.from_request!(request, actor: @decider)
    assert request.reload.resume_readable_by?(@decider), "the internship it produced is open"

    placement.activate!(actor: @decider)
    placement.complete!(actor: @decider)
    assert_not request.reload.resume_readable_by?(@decider), "the internship ended"
  end

  test "unsharing closes it, and so does deleting the résumé at its source" do
    request = submitted_request
    request.share_resume!(actor: @student)

    request.unshare_resume!(actor: @student)
    assert_not request.resume_readable_by?(@decider)

    request.share_resume!(actor: @student)
    @profile.reload.resume.purge
    assert_not request.reload.resume_readable_by?(@decider),
               "removing it from the profile removes it from every request at once"
  end

  test "nobody outside the request reads the résumé" do
    request = submitted_request
    request.share_resume!(actor: @student)

    [ users(:two), users(:instructor), users(:admin), nil ].each do |user|
      assert_not request.resume_readable_by?(user)
    end
  end

  # ---- Deliverables ---------------------------------------------------------

  test "the placed student adds work, and it is audited by name and not by content" do
    placement = active_placement

    assert_difference -> { AuditEvent.where(action: "internship_deliverable_added").count }, 1 do
      deliverable = build_deliverable(placement)
      deliverable.save!
    end

    event = AuditEvent.where(action: "internship_deliverable_added").last
    assert_equal "report.pdf", event.params["filename"]
    assert_not event.params.value?("%PDF-1.4 the contents")
  end

  test "only the placed student adds work, and only while the placement is open" do
    placement = active_placement

    [ @decider, users(:two), users(:admin) ].each do |actor|
      assert_not build_deliverable(placement, author: actor).valid?
    end

    placement.complete!(actor: @decider)
    assert_not build_deliverable(placement).valid?, "a finished internship takes no more work"
  end

  test "the allowlist and the ceiling are the ones the candidate profile already enforces" do
    placement = active_placement

    assert_equal CandidateProfile::MAX_ATTACHMENT_BYTES, InternshipDeliverable::MAX_BYTES
    CandidateProfile::PORTFOLIO_CONTENT_TYPES.each do |type|
      assert_includes InternshipDeliverable::CONTENT_TYPES, type
    end

    # Active Storage re-identifies the type from the bytes and the filename, so
    # a declared content type cannot talk its way past the allowlist.
    executable = build_deliverable(placement, filename: "payload.exe", body: "MZ\x90\x00",
                                   content_type: "application/pdf")
    assert_not executable.valid?
    assert_predicate executable.errors[:file], :any?
    assert_not_includes InternshipDeliverable::CONTENT_TYPES, executable.file.content_type
  end

  test "the company reads work while the internship runs, and nobody else ever does" do
    placement = active_placement
    deliverable = build_deliverable(placement)
    deliverable.save!

    assert deliverable.readable_by?(@student)
    assert deliverable.readable_by?(@decider)

    # Decision 5 was offered a faculty reader and did not take one.
    supervisor = users(:instructor)
    placement.faculty_assignments.create!(faculty: supervisor, assigned_by: users(:admin))
    assert_not deliverable.readable_by?(supervisor),
               "the assignment grants the placement and its reports, not the student's files"

    [ users(:two), users(:admin), nil ].each { |user| assert_not deliverable.readable_by?(user) }
  end

  test "the company loses the work when the internship ends; the student keeps it" do
    placement = active_placement
    deliverable = build_deliverable(placement)
    deliverable.save!

    placement.complete!(actor: @decider)

    assert_not deliverable.reload.readable_by?(@decider)
    assert deliverable.readable_by?(@student)
  end

  test "the student removes their own work and the company cannot" do
    placement = active_placement
    deliverable = build_deliverable(placement)
    deliverable.save!

    [ @decider, users(:admin) ].each do |actor|
      assert_raises(ActiveRecord::RecordInvalid) { deliverable.destroy_for!(actor:) }
    end

    assert_difference -> { AuditEvent.where(action: "internship_deliverable_removed").count }, 1 do
      assert_difference -> { InternshipDeliverable.count }, -1 do
        deliverable.destroy_for!(actor: @student)
      end
    end
  end

  private
    def attach_resume
      @profile.resume.attach(io: StringIO.new("%PDF-1.4 the contents"), filename: "resume.pdf",
                             content_type: "application/pdf")
    end

    def submitted_request
      request = @organization.internship_requests.create!(student: @student, motivation: "Your routing work",
                                                          learning_goals: "Optimisation")
      request.submit!(actor: @student)
      request
    end

    def active_placement
      request = submitted_request
      request.approve!(actor: @decider)
      placement = InternshipPlacement.from_request!(request, actor: @decider)
      placement.activate!(actor: @decider)
      placement
    end

    def build_deliverable(placement, author: @student, content_type: "application/pdf",
                          filename: "report.pdf", body: "%PDF-1.4 the contents")
      deliverable = placement.deliverables.new(title: "Week one report", author:)
      deliverable.file.attach(io: StringIO.new(body), filename:, content_type:)
      deliverable
    end
end
