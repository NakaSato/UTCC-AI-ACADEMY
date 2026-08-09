require "test_helper"

class Recruitment::OrganizationsControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:admin) }

  test "admin creates an organization with an owner and audit events" do
    assert_difference "Organization.count", 1 do
      assert_difference "OrganizationMembership.count", 1 do
        assert_difference "AuditEvent.count", 2 do
          post companies_path, params: {
            organization: { name: "North Star", slug: "", owner_id: users(:one).id }
          }
        end
      end
    end

    organization = Organization.order(:id).last
    assert_redirected_to company_path(organization)
    assert_equal "north-star", organization.slug
    assert_predicate organization.memberships.find_by(user: users(:one)), :owner?
    assert_equal "recruitment_organization_created", AuditEvent.order(:id).last(2).first.action
  end

  test "non-admin cannot create an organization or grant membership" do
    sign_out
    sign_in_as users(:one)

    assert_no_difference "Organization.count" do
      post companies_path, params: {
        organization: { name: "Forbidden", owner_id: users(:one).id }
      }
    end
    assert_redirected_to root_path

    organization = Organization.create!(name: "Existing", creator: users(:admin))
    assert_no_difference "OrganizationMembership.count" do
      post memberships_company_path(organization), params: {
        membership: { user_id: users(:two).id, role: "recruiter" }
      }
    end
    assert_redirected_to root_path
  end

  test "a member can view an organization and a non-member cannot" do
    organization = Organization.create!(name: "Member Org", creator: users(:admin))
    organization.memberships.create!(user: users(:one), role: "owner")

    sign_out
    sign_in_as users(:one)
    get company_path(organization)
    assert_response :success
    assert_select "h1", "Member Org"


    sign_out
    sign_in_as users(:two)
    get company_path(organization)
    assert_response :not_found
  end

  test "admin grants and revokes a non-owner membership" do
    organization = Organization.create!(name: "Grant Org", creator: users(:admin))
    organization.memberships.create!(user: users(:one), role: "owner")

    assert_difference "OrganizationMembership.count", 1 do
      post memberships_company_path(organization), params: {
        membership: { user_id: users(:two).id, role: "recruiter" }
      }
    end
    membership = organization.memberships.find_by!(user: users(:two))
    assert_redirected_to company_path(organization)
    assert_equal "recruiter", membership.role

    assert_difference -> { organization.memberships.active.count }, -1 do
      delete membership_company_path(organization, users(:two).id)
    end
    assert_redirected_to company_path(organization)
    assert_equal "revoked", membership.reload.status
  end

  test "admin cannot revoke the organization owner" do
    organization = Organization.create!(name: "Owner Org", creator: users(:admin))
    membership = organization.memberships.create!(user: users(:one), role: "owner")

    delete membership_company_path(organization, users(:one).id)

    assert_redirected_to company_path(organization)
    assert_predicate membership.reload, :active?
  end
end
