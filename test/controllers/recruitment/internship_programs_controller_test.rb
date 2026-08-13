require "test_helper"

class Recruitment::InternshipProgramsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @organization = Organization.create!(name: "Internship Controller Org", creator: users(:admin))
    @organization.memberships.create!(user: users(:one), role: "owner")
    @organization.memberships.create!(user: users(:two), role: "recruiter")
    @organization.memberships.create!(user: users(:instructor), role: "mentor")
    sign_in_as users(:two)
  end

  def program_attributes
    {
      name: "AI Internship", department: "Innovation", description: "Build with a team.", duration_weeks: 10,
      max_students: 3, mentor_id: users(:instructor).id, required_skills: "Communication",
      learning_outcomes: "Ship a reviewed prototype.", working_days: "Monday to Friday", remote_policy: "hybrid",
      paid: "0", certificate_policy: "Certificate after review", equipment_provided: "Laptop"
    }
  end

  # The form raised on every render, for everybody allowed to open it, from the
  # day it shipped: `form_with model: [ @organization, @program ]` asks Rails for
  # `organization_recruitment_internship_program_path`, and these routes are
  # named `company_…`. Every test here posted straight to the create action, so
  # nothing ever rendered the screen a person has to use to get there. A link
  # crawl found it as a 500 on `/company/:slug/internship_programs/new`.
  test "the screens that carry the form render, and post where the routes are" do
    get new_company_internship_program_path(@organization)

    assert_response :success
    assert_select "form[action=?][method=post]", company_internship_programs_path(@organization)

    program = @organization.internship_programs.create!(creator: users(:two), mentor: users(:instructor),
                                                        name: "Rendered", department: "Ops",
                                                        description: "d", required_skills: "s",
                                                        learning_outcomes: "o", working_days: "Mon",
                                                        certificate_policy: "c")
    get edit_company_internship_program_path(@organization, program)

    assert_response :success
    assert_select "form[action=?]", company_internship_program_path(@organization, program)
    assert_select "input[name=?][value=?]", "_method", "patch"
  end

  test "an authorized recruiter creates and submits an internship program" do
    assert_difference [ "Recruitment::InternshipProgram.count", "AuditEvent.count" ], 1 do
      post company_internship_programs_path(@organization), params: {
        recruitment_internship_program: program_attributes
      }
    end

    program = @organization.internship_programs.order(:id).last
    assert_redirected_to company_internship_program_path(@organization, program)
    assert_equal "draft", program.status

    assert_difference "AuditEvent.count", 1 do
      post submit_company_internship_program_path(@organization, program)
    end
    assert_equal "review", program.reload.status
  end

  test "a non-member cannot access organization internship management" do
    sign_out
    sign_in_as users(:student)

    get company_internship_programs_path(@organization)

    assert_response :not_found
  end

  test "a published program is visible to candidates" do
    program = @organization.internship_programs.create!(program_attributes.merge(creator: users(:two)))
    program.transition_to!("review")
    program.transition_to!("published")

    get recruitment_internship_path(program)

    assert_response :success
    assert_select "h1", text: "AI Internship"
  end

  test "an applicant sees the private internship preparation guide" do
    program = @organization.internship_programs.create!(program_attributes.merge(creator: users(:two)))
    program.transition_to!("review")
    program.transition_to!("published")
    program.applications.create!(student: users(:student), statement: "I want to learn.")

    sign_out
    sign_in_as users(:student)
    get recruitment_internship_path(program)

    assert_response :success
    assert_select "body", /#{I18n.t("recruitment.internships.assistant_title")}/
    assert_select "body", /#{I18n.t("recruitment.internships.assistant_items.wait_for_decision")}/
  end
end
