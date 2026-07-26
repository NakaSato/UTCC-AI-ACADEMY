class CreateLandingTexts < ActiveRecord::Migration[8.1]
  # The landing page's copy as an admin wrote it, so the front door can be
  # rewritten without a deploy.
  #
  # For a card that ships with the app this is an override layer, and only
  # departures live here: `config/locales/{th,en}.yml` is still what a fresh
  # install renders, a row shadows one string in one language, and deleting it
  # puts the shipped copy back. An empty table is the app as shipped, which is
  # why there is no row per card and nothing to satisfy for copy nobody touched.
  #
  # For a card an admin added there is no shipped copy to override, so a row here
  # is the only copy that string has — see `Landing.copy`, which reads both.
  #
  # `key` is the path under `landing.` — "topics.prompting.title" — so the join
  # to the locale file stays the keyed one the page already used.
  def change
    create_table :landing_texts do |t|
      t.string :key, null: false
      t.string :locale, null: false
      t.text :value, null: false

      t.timestamps
    end

    # One override per string per language, and the whole table is read at once.
    add_index :landing_texts, %i[ key locale ], unique: true
  end
end
