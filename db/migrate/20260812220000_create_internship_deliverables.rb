class CreateInternshipDeliverables < ActiveRecord::Migration[8.1]
  def change
    # ADR-0041 decision 5, answered 2026-08-13. Two different things, and only
    # one of them is a new file.
    #
    # A résumé is not copied. The student already has one on their candidate
    # profile under SPEC-0029's contract, and a request records that they chose
    # to share it — a timestamp, not a blob. Storing a second copy would mean
    # two retention clocks and two deletions for the document the platform is
    # least entitled to duplicate.
    add_column :internship_requests, :resume_shared_at, :datetime

    # A deliverable is genuinely new: the work a student produced during a
    # placement has no home anywhere in the repository. A record rather than a
    # bare attachment, so an upload has an author, a title, an audit row, and
    # one place where deletion is authorized.
    create_table :internship_deliverables do |t|
      t.references :internship_placement, null: false, foreign_key: true, index: false
      t.references :author, null: false, foreign_key: { to_table: :users }, index: false
      t.string :title, limit: 160, null: false
      t.timestamps
    end

    add_index :internship_deliverables, [ :internship_placement_id, :created_at ]
    add_index :internship_deliverables, :author_id
  end
end
