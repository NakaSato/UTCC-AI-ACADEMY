class CreateRecruitmentJobApplicationMessages < ActiveRecord::Migration[8.1]
  def change
    create_table :recruitment_job_application_messages do |t|
      t.references :job_application, null: false,
                   foreign_key: { to_table: :recruitment_job_applications }, index: false
      t.references :sender, null: false, foreign_key: { to_table: :users }, index: false
      t.text :body, null: false, default: ""
      t.datetime :sent_at, null: false
      t.timestamps
    end

    add_index :recruitment_job_application_messages, [ :job_application_id, :sent_at, :id ],
              name: "recruitment_job_application_messages_history"
    add_check_constraint :recruitment_job_application_messages,
                         "char_length(btrim(body)) > 0 AND char_length(body) <= 4000",
                         name: "recruitment_job_application_messages_body"
  end
end
