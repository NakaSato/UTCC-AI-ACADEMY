require "test_helper"

# The first path in this application by which one person reads a file another
# person uploaded, so the assertions that matter are about the download: who is
# refused, and that a browser is never asked to interpret what it receives.
class InternshipDocumentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @organization = Organization.create!(name: "Document Co", creator: users(:admin),
                                         accepts_internship_requests: true)
    @decider = users(:one)
    @organization.memberships.create!(user: @decider, role: "owner")
    @student = users(:student)
    @profile = CandidateProfile.create!(user: @student, application_data_reuse_consent: true)
    @profile.resume.attach(io: StringIO.new("%PDF-1.4 a résumé"), filename: "resume.pdf",
                           content_type: "application/pdf")
  end

  # ---- The shared résumé ----------------------------------------------------

  test "a student shares and unshares their résumé from their own request" do
    request = submitted_request
    sign_in_as @student

    post resume_internship_request_path(request)
    assert_redirected_to internship_request_path(request)
    assert_predicate request.reload, :resume_shared?

    delete unshare_resume_internship_request_path(request)
    assert_not request.reload.resume_shared?
  end

  test "nobody shares a résumé on somebody else's request" do
    request = submitted_request

    [ @decider, users(:two), users(:admin) ].each do |actor|
      sign_in_as actor
      post resume_internship_request_path(request)

      assert_response :not_found
      assert_not request.reload.resume_shared?
      sign_out
    end
  end

  test "the company downloads it as an attachment while the request is open" do
    request = submitted_request
    request.share_resume!(actor: @student)

    sign_in_as @decider
    get download_resume_internship_request_path(request)

    assert_response :success
    assert_equal "application/pdf", response.media_type
    assert_match(/\Aattachment;/, response.headers["Content-Disposition"],
                 "somebody else's upload is never rendered in a reader's browser")
    assert_equal "nosniff", response.headers["X-Content-Type-Options"]
  end

  test "the download closes with the decision that closed the request" do
    request = submitted_request
    request.share_resume!(actor: @student)
    request.reject!(actor: @decider, reason: "Not this term")

    sign_in_as @decider
    get download_resume_internship_request_path(request)

    assert_response :not_found
  end

  test "an unshared résumé is not downloadable by anyone but its owner" do
    request = submitted_request

    sign_in_as @decider
    get download_resume_internship_request_path(request)
    assert_response :not_found
    sign_out

    sign_in_as @student
    get download_resume_internship_request_path(request)
    assert_response :not_found, "there is nothing shared to read yet"
  end

  # ---- Deliverables ---------------------------------------------------------

  test "the placed student uploads work and the company downloads it as an attachment" do
    placement = active_placement

    sign_in_as @student
    assert_difference -> { InternshipDeliverable.count }, 1 do
      post deliverables_internship_placement_path(placement), params: {
        internship_deliverable: { title: "Route analysis", file: uploaded_file }
      }
    end
    assert_redirected_to internship_placement_path(placement)
    sign_out

    deliverable = placement.deliverables.last
    sign_in_as @decider
    get download_deliverable_internship_placement_path(placement, deliverable_id: deliverable.id)

    assert_response :success
    assert_match(/\Aattachment;/, response.headers["Content-Disposition"])
    assert_equal "nosniff", response.headers["X-Content-Type-Options"]
  end

  test "a file the allowlist refuses never becomes a deliverable" do
    placement = active_placement

    sign_in_as @student
    assert_no_difference -> { InternshipDeliverable.count } do
      post deliverables_internship_placement_path(placement), params: {
        internship_deliverable: { title: "Tool", file: uploaded_file(name: "payload.exe", body: "MZ\x90\x00") }
      }
    end

    assert_redirected_to internship_placement_path(placement)
  end

  test "nobody but the placed student uploads work to a placement" do
    placement = active_placement

    [ @decider, users(:two) ].each do |actor|
      sign_in_as actor
      assert_no_difference -> { InternshipDeliverable.count } do
        post deliverables_internship_placement_path(placement), params: {
          internship_deliverable: { title: "Mine now", file: uploaded_file }
        }
      end
      sign_out
    end
  end

  test "the company loses the download when the internship ends" do
    placement = active_placement
    deliverable = create_deliverable(placement)
    placement.complete!(actor: @decider)

    sign_in_as @decider
    get download_deliverable_internship_placement_path(placement, deliverable_id: deliverable.id)
    assert_response :not_found
    sign_out

    sign_in_as @student
    get download_deliverable_internship_placement_path(placement, deliverable_id: deliverable.id)
    assert_response :success, "the student keeps their own work"
  end

  # The supervisor reads the placement and its weekly reports (decision 7) and
  # was deliberately not given the student's files.
  test "the faculty supervisor cannot download a deliverable" do
    placement = active_placement
    deliverable = create_deliverable(placement)
    supervisor = users(:instructor)
    placement.faculty_assignments.create!(faculty: supervisor, assigned_by: users(:admin))

    sign_in_as supervisor
    get download_deliverable_internship_placement_path(placement, deliverable_id: deliverable.id)

    assert_response :not_found
  end

  test "the student removes their work and the company cannot" do
    placement = active_placement
    deliverable = create_deliverable(placement)

    sign_in_as @decider
    delete deliverable_internship_placement_path(placement, deliverable_id: deliverable.id)
    assert_equal 1, placement.deliverables.count
    sign_out

    sign_in_as @student
    delete deliverable_internship_placement_path(placement, deliverable_id: deliverable.id)
    assert_equal 0, placement.deliverables.count
  end

  private
    def uploaded_file(name: "report.pdf", body: "%PDF-1.4 the contents", type: "application/pdf")
      Rack::Test::UploadedFile.new(StringIO.new(body), type, original_filename: name)
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

    def create_deliverable(placement)
      deliverable = placement.deliverables.new(title: "Route analysis", author: @student)
      deliverable.file.attach(io: StringIO.new("%PDF-1.4 the contents"), filename: "report.pdf",
                              content_type: "application/pdf")
      deliverable.save!
      deliverable
    end
end
