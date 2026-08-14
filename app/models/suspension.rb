# Suspending an account, and giving it back.
#
# The shape is a retired lesson's (ADR-0055): the row stays and everything
# pointing at it stays, so a suspended learner's completions still count on the
# leaderboard and in their section's averages. The work was done. What goes away
# is access — and not only the next sign-in: `Session.usable` resolves a cookie
# through the account behind it, so the sessions they already had open stop
# authenticating on their next request rather than lasting until they age out.
module Suspension
  # One event per account, never one per batch. The audit log answers "what
  # happened to this person", and a row saying "12 accounts suspended" answers
  # it for nobody.
  def self.apply(scope, restoring:)
    targets = restoring ? scope.suspended : scope.unsuspended
    at = restoring ? nil : Time.current

    User.transaction do
      changed = targets.to_a
      changed.each do |user|
        user.update!(suspended_at: at)
        AuditEvent.record(restoring ? "account_restored" : "account_suspended", name: user.name)
      end
      changed.size
    end
  end
end
