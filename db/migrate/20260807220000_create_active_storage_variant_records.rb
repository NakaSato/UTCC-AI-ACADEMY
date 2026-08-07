class CreateActiveStorageVariantRecords < ActiveRecord::Migration[8.1]
  def change
    create_table :active_storage_variant_records do |t|
      t.belongs_to :blob, null: false, index: false, foreign_key: { to_table: :active_storage_blobs }
      t.string :variation_digest, null: false

      t.index [ :blob_id, :variation_digest ], unique: true,
              name: "index_active_storage_variant_records_uniqueness"
    end
  end
end
