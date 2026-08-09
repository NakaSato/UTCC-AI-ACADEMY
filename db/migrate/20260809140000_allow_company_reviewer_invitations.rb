class AllowCompanyReviewerInvitations < ActiveRecord::Migration[8.1]
  # organization_memberships has no role check constraint, so only the
  # invitation constraint has to learn the new role.
  def up
    remove_check_constraint :organization_invitations, name: "organization_invitations_role"
    add_check_constraint :organization_invitations,
                         "role IN ('recruiter', 'hiring_manager', 'mentor', 'company_reviewer')",
                         name: "organization_invitations_role"
  end

  def down
    remove_check_constraint :organization_invitations, name: "organization_invitations_role"
    add_check_constraint :organization_invitations,
                         "role IN ('recruiter', 'hiring_manager', 'mentor')",
                         name: "organization_invitations_role"
  end
end
