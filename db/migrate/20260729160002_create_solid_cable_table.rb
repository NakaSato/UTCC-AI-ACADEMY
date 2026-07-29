class CreateSolidCableTable < ActiveRecord::Migration[8.1]
  # db/cable_schema.rb as a migration — see CreateSolidQueueTables for why the
  # three solid_* schemas moved into the primary database.
  #
  # This is the table the notification bell's socket polls every 100ms, and it is
  # now the same database the screens read from. That poll used to be isolated in
  # a database of its own; what keeps it cheap is `message_retention: 1.day` in
  # config/cable.yml and the index on created_at below, not the separation.
  def change
    create_table :solid_cable_messages do |t|
      t.binary :channel, limit: 1024, null: false
      t.binary :payload, limit: 536870912, null: false
      t.datetime :created_at, null: false
      t.integer :channel_hash, limit: 8, null: false

      t.index :channel, name: "index_solid_cable_messages_on_channel"
      t.index :channel_hash, name: "index_solid_cable_messages_on_channel_hash"
      t.index :created_at, name: "index_solid_cable_messages_on_created_at"
    end
  end
end
