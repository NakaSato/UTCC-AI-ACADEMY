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

  # Parity is agreement, not correctness: two files can be identically wrong and
  # pass every test above. Nineteen strings did — twelve reader controls filed
  # under the wrong parent, four keys YAML read as booleans, and two that were
  # never written — and each rendered "translation missing" in both languages on
  # a shipped screen. These two tests are the half parity cannot see.
  #
  # Only literal keys are checkable here; the 177 interpolated call sites are
  # covered by `raise_on_missing_translations` wherever a test renders them.
  LITERAL_KEY = /(?:I18n\.)?\bt[\( ]\s*["']([a-z][a-z0-9_]*(?:\.[a-z0-9_]+)+)["']/
  SOURCES = Rails.root.glob("{app,lib}/**/*.{rb,erb}").freeze

  test "every literal translation key the code asks for is defined" do
    asked = SOURCES.flat_map do |file|
      file.readlines.each_with_index.flat_map do |line, index|
        line.scan(LITERAL_KEY).map { |(key)| [ key, "#{file.relative_path_from(Rails.root)}:#{index + 1}" ] }
      end
    end

    # A key may name a leaf or the parent of one — `t("scope")` returning a hash
    # is how the pluralization and state vocabularies are read.
    defined_keys = ENGLISH.keys.to_set
    parents = ENGLISH.keys.flat_map { |key| key.split(".").each_with_object([]) { |part, all| all << [ all.last, part ].compact.join(".") } }.to_set
    missing = asked.reject { |key, _| defined_keys.include?(key) || parents.include?(key) }

    assert_empty missing, <<~MESSAGE
      #{missing.length} key(s) are asked for by name and defined nowhere, which is
      the one failure a reader sees in both languages at once:

      #{missing.uniq.first(25).map { |key, where| "#{key}  (#{where})" }.join("\n")}
    MESSAGE
  end

  # `yes:`, `no:`, `true:`, `on:`, and `off:` are booleans in YAML 1.1, so the
  # key stops being the word that was written. `t("…internships.yes")` then looks
  # up a key that is not there while the file plainly shows one that is. Quoting
  # is the whole fix, and this is the only thing that makes the omission visible.
  test "no locale key parses as anything but a string" do
    coerced = { en: :en, th: :th }.flat_map do |_, locale|
      tree = YAML.unsafe_load_file(ROOT.join("#{locale}.yml")).fetch(locale.to_s)
      non_string_keys(tree).map { |key| "#{locale}.#{key}" }
    end

    assert_empty coerced, <<~MESSAGE
      #{coerced.length} key(s) are not strings after YAML parses them, so the word
      written in the file is not the word the code can ask for. Quote them:

      #{coerced.join("\n")}
    MESSAGE
  end

  def non_string_keys(node, prefix = "")
    return [] unless node.is_a?(Hash)

    node.flat_map do |key, value|
      path = "#{prefix}#{key}"
      (key.is_a?(String) ? [] : [ "#{path} (#{key.class})" ]) + non_string_keys(value, "#{path}.")
    end
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
