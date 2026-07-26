class CreateAuditEvents < ActiveRecord::Migration[8.1]
  # Who did what on /admin. Written at the moment an admin action succeeds,
  # which is why this table could not exist until those actions did.
  #
  # It matters more than it did: /admin is the only place a role is granted, it
  # enrols and unenrols students, and it can delete a landing card along with
  # its copy in both languages. All of that is irreversible from the screen and
  # none of it named anyone.
  #
  # `params` carries the interpolations, not the sentence — the copy is
  # `audit.<action>` in the locale files, so a line reads in whichever language
  # the reader is using now, not whichever the actor was using then. The level
  # is not here either: it is derived from the action, so reclassifying one is a
  # deploy rather than a backfill.
  def change
    create_table :audit_events do |t|
      # The actor. Everything in this table is something a person did.
      t.references :user, null: false, foreign_key: true
      t.string :action, null: false
      t.json :params, null: false, default: {}

      t.timestamps
    end

    # The tab is newest-first over everything; the second index is for the day
    # somebody asks what one admin has been doing.
    add_index :audit_events, :created_at
    add_index :audit_events, %i[ user_id created_at ]
  end
end
