class AllowCompanyReviewerInvitations < ActiveRecord::Migration[8.1]
  # organization_memberships has no role check constraint, so only the
  # invitation constraint has to learn the new role.
  def up
    remove_check_constraint :organization_invitations, name: "organization_invitations_role"
    add_check_constraint :organization_invitations,
                         "role IN ('recruiter', 'hiring_manager', 'mentor', 'company_reviewer')",
                         name: "organization_invitations_role"
  end

  # Narrowing the constraint back would fail validation against any row already
  # holding the new role, aborting the rollback partway through the release. Say
  # so up front instead: rewriting or deleting real invitation history is a
  # decision for the release owner, not something a migration should do quietly.
  def down
    existing = select_value(
      "SELECT COUNT(*) FROM organization_invitations WHERE role = 'company_reviewer'"
    ).to_i

    if existing.positive?
      raise ActiveRecord::IrreversibleMigration,
            "#{existing} organization_invitations row(s) hold role 'company_reviewer'. " \
            "Decide what happens to that invitation history — reassign the role or delete the rows — " \
            "then re-run this rollback."
    end

    remove_check_constraint :organization_invitations, name: "organization_invitations_role"
    add_check_constraint :organization_invitations,
                         "role IN ('recruiter', 'hiring_manager', 'mentor')",
                         name: "organization_invitations_role"
  end
end
