require "test_helper"

class MigrationReversibilityTest < ActiveSupport::TestCase
  # Migration classes are not autoloaded, so load the file under test by path.
  MIGRATION_PATH = Rails.root.join("db/migrate/20260809140000_allow_company_reviewer_invitations.rb")

  test "the role migration refuses to roll back over real invitation history" do
    require MIGRATION_PATH.to_s

    organization = Organization.create!(name: "Rollback Org", creator: users(:admin))
    organization.memberships.create!(user: users(:one), role: "owner")
    organization.invitations.create!(inviter: users(:one), invitee: users(:two), role: "company_reviewer")

    migration = AllowCompanyReviewerInvitations.new
    migration.verbose = false
    error = assert_raises(ActiveRecord::IrreversibleMigration) { migration.down }

    assert_match(/company_reviewer/, error.message)
    assert_predicate OrganizationInvitation.where(role: "company_reviewer").count, :positive?,
      "a refused rollback must leave the invitation history untouched"
  end
end
