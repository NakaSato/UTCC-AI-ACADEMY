class CreateNotifications < ActiveRecord::Migration[8.1]
  # In-app rows only — nothing is delivered anywhere. A notification is written
  # at the moment something notify-worthy actually happens (an enrolment, a role
  # grant, an integrity decision), which is why this table could not exist until
  # those actions did.
  #
  # `params` carries the interpolations, not the sentence: copy lives in the
  # locale files as everywhere, so a notification renders in whichever language
  # the reader is using NOW, not whichever the writer was using then.
  def change
    create_table :notifications do |t|
      t.references :user, null: false, foreign_key: true
      t.string :kind, null: false
      t.json :params, null: false, default: {}
      t.datetime :read_at

      t.timestamps
    end

    add_index :notifications, %i[ user_id read_at ]
    add_index :notifications, %i[ user_id created_at ]
  end
end
