require "test_helper"
require "yaml"

# The UI is bilingual, and the repository says the two locale files must stay in
# step. Nothing checked it. Discipline had held — the files are identical in
# shape today — but the failure this prevents is the quiet kind: Rails is
# configured with `fallbacks = [:en]`, so a key missing from Thai does not raise
# and does not render "translation missing". It renders English, to a reader who
# chose Thai, on a page that looks like it worked.
#
# It reads the two files rather than the I18n backend on purpose. The backend
# also carries the framework's own English defaults, which have no Thai
# counterpart and never should; the invariant is about these two files.
class LocaleParityTest < ActiveSupport::TestCase
  ROOT = Rails.root.join("config/locales")

  def self.keys_in(locale)
    tree = YAML.unsafe_load_file(ROOT.join("#{locale}.yml")).fetch(locale.to_s)
    flatten(tree)
  end

  def self.flatten(node, prefix = "")
    return { prefix.chomp(".") => node } unless node.is_a?(Hash)

    node.reduce({}) { |all, (key, value)| all.merge(flatten(value, "#{prefix}#{key}.")) }
  end

  ENGLISH = keys_in(:en)
  THAI = keys_in(:th)

  test "every English key has a Thai counterpart" do
    missing = ENGLISH.keys - THAI.keys

    assert_empty missing, <<~MESSAGE
      #{missing.length} key(s) exist in English and not in Thai. Because fallbacks
      are on, each one renders English to a Thai reader rather than failing:

      #{missing.first(25).join("\n")}
    MESSAGE
  end

  # The other direction is not symmetrical in consequence — an orphaned Thai key
  # renders nothing to anybody — but it is the same drift, and it usually means
  # an English key was renamed and its translation left behind.
  test "every Thai key has an English counterpart" do
    orphaned = THAI.keys - ENGLISH.keys

    assert_empty orphaned, <<~MESSAGE
      #{orphaned.length} key(s) exist in Thai and not in English, usually a rename
      that left its translation behind:

      #{orphaned.first(25).join("\n")}
    MESSAGE
  end

  # A key present with nothing behind it fails exactly like a missing one, and
  # is harder to see in a diff.
  test "no locale key is defined but empty" do
    blank = { en: ENGLISH, th: THAI }.flat_map do |locale, tree|
      tree.filter_map { |key, value| "#{locale}.#{key}" if value.nil? || (value.is_a?(String) && value.strip.empty?) }
    end

    assert_empty blank, "these keys are defined with nothing behind them: #{blank.join(', ')}"
  end
end
