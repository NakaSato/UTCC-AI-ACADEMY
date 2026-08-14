class CreateSyllabusTexts < ActiveRecord::Migration[8.1]
  def change
    # One syllabus string in one language, keyed on something that survives a
    # reorder. `course.curricula.<CODE>.modules[i].topics[j]` is keyed on
    # position, so today a topic's name is wherever it happens to sit: move a
    # lesson up and every lesson below it takes the next one's name, in both
    # languages at once. A builder cannot exist over copy that works like that.
    #
    # The shape is LandingText's, for LandingText's reasons: the locale files
    # stay the shipped default, a row shadows one string in one language, and a
    # string with no shipped default (a topic somebody added) is only ever a row.
    create_table :syllabus_texts do |t|
      t.string :key, null: false
      t.string :locale, null: false
      t.text :value, null: false
      t.timestamps

      t.index [ :key, :locale ], unique: true
      t.check_constraint "length(value) BETWEEN 1 AND 2000", name: "syllabus_texts_value"
    end
  end
end
