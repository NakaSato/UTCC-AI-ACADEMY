class CreateSolidCacheTable < ActiveRecord::Migration[8.1]
  # db/cache_schema.rb as a migration — see CreateSolidQueueTables for why the
  # three solid_* schemas moved into the primary database.
  #
  # The limits on the binary columns are what the gem's own schema declares. They
  # are advisory on Postgres, which stores both as bytea and enforces neither;
  # they are kept so this reads as the same schema the gem ships rather than a
  # local variation of it. The size that actually binds is `max_size` in
  # config/cache.yml, which Solid Cache trims against.
  def change
    create_table :solid_cache_entries do |t|
      t.binary :key, limit: 1024, null: false
      t.binary :value, limit: 536870912, null: false
      t.datetime :created_at, null: false
      t.integer :key_hash, limit: 8, null: false
      t.integer :byte_size, limit: 4, null: false

      t.index :byte_size, name: "index_solid_cache_entries_on_byte_size"
      t.index %i[ key_hash byte_size ], name: "index_solid_cache_entries_on_key_hash_and_byte_size"
      t.index :key_hash, name: "index_solid_cache_entries_on_key_hash", unique: true
    end
  end
end
