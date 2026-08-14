class SuspendAccountsRatherThanDeleteThem < ActiveRecord::Migration[8.1]
  def change
    # When an account lost its access, rather than whether it did.
    #
    # Suspension is the same shape as a lesson's retirement (ADR-0055): the row
    # stays and everything pointing at it stays, so a suspended learner's
    # completions still count on the leaderboard and in their section's averages.
    # What goes away is the ability to sign in — and the ability to keep using a
    # session opened before the suspension.
    add_column :users, :suspended_at, :datetime
  end
end
