require "test_helper"

# The placeholder data sources that stand in for real models. They are pure
# Ruby, so these tests are about the derived values and the locale wiring —
# the parts that will need to keep working when real records replace them.
class PlaceholderContentTest < ActiveSupport::TestCase
  test "every course resolves its copy in both locales" do
    I18n.available_locales.each do |locale|
      I18n.with_locale(locale) do
        CourseCatalog.all.each do |course|
          assert course.title.present?, "#{course.code} has no #{locale} title"
          assert course.description.present?, "#{course.code} has no #{locale} description"
          assert course.instructor.present?, "#{course.code} has no #{locale} instructor"
          assert course.level_name.present?, "#{course.code} has no #{locale} level"
        end
      end
    end
  end

  # The card's avatar plate abbreviates the word after the academic title, so a
  # locale entry that drops the space would silently render the title instead.
  test "instructor initials abbreviate the given name in both locales" do
    I18n.available_locales.each do |locale|
      I18n.with_locale(locale) do
        CourseCatalog.all.each do |course|
          given_name = course.instructor.split.last
          initials = course.instructor_initials

          assert_equal 2, initials.length, "#{course.code} #{locale} initials: #{initials.inspect}"
          assert given_name.start_with?(initials), "#{course.code} #{locale}: #{given_name} vs #{initials}"
        end
      end
    end
  end

  test "filter counts match the courses each filter actually selects" do
    counts = CourseCatalog.filter_counts

    assert_equal CourseCatalog.all.size, counts[:all]
    CourseCatalog::FILTERS.each do |filter|
      assert_equal CourseCatalog.all.count { it.tagged?(filter) }, counts[filter], "filter #{filter}"
    end
  end

  test "a started course reports progress and an unstarted one does not" do
    started = CourseCatalog.find("AI1101")
    unstarted = CourseCatalog.find("AI2201")

    assert_predicate started, :started?
    assert_equal 32, started.percent
    assert_not_predicate unstarted, :started?
    assert_equal 0, unstarted.percent
  end

  test "map rows only descend into open groups" do
    roots_only = KnowledgeMap.rows(open: [])
    assert_equal 1, roots_only.size
    assert_equal 0, roots_only.first.depth

    default = KnowledgeMap.rows
    assert_operator default.size, :>, roots_only.size
    assert default.all? { KnowledgeMap::DEFAULT_OPEN.include?(it.node.id) || it.depth.positive? }
  end

  test "path_to returns the full ancestry and nil for a stranger" do
    assert_equal %w[ cs ml ml-prep ml-split ], KnowledgeMap.path_to("ml-split").map(&:id)
    assert_nil KnowledgeMap.path_to("not-a-topic")
    assert_nil KnowledgeMap.find("not-a-topic")
  end

  test "map nodes classify their own completion" do
    assert_predicate KnowledgeMap.find("py-var"), :fully_learned?
    assert_predicate KnowledgeMap.find("ml-prep"), :partly_learned?
    assert_not_predicate KnowledgeMap.find("gen"), :partly_learned?
    assert_equal 11, KnowledgeMap.find("ml-prep").remaining
  end

  test "every map node resolves a name in both locales" do
    I18n.available_locales.each do |locale|
      I18n.with_locale(locale) do
        KnowledgeMap.each_node.each do |node, _trail|
          assert node.name.present?, "#{node.id} has no #{locale} name"
          assert_no_match(/translation missing/, node.name)
        end
      end
    end
  end

  test "syllabus pairs each topic with its own kind and duration" do
    modules = Syllabus.modules

    assert_equal Syllabus::ENTRIES.size, modules.size
    modules.each_with_index do |mod, index|
      assert_equal index + 1, mod.number
      assert_equal Syllabus::ENTRIES[index][2].size, mod.topics.size
      assert mod.title.present?
      mod.topics.each { assert it.name.present? }
    end

    supervised = modules[1].topics[2]
    assert_equal "Supervised vs. Unsupervised", supervised.name
    assert_equal I18n.t("course.kind.mix"), supervised.kind_name
  end

  test "lesson steps map to labels and progress" do
    assert_equal :theory, LessonContent.step_for(nil)
    assert_equal :theory, LessonContent.step_for("nonsense")
    assert_equal :code, LessonContent.step_for("code")

    assert_equal 100, LessonContent.percent_for(:summary)
    assert_equal LessonContent::STEPS.size, LessonContent.options.size
  end

  test "the coding task patterns accept a correct solution and reject the starter" do
    solution = <<~PYTHON
      from sklearn.model_selection import train_test_split
      X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)
    PYTHON

    patterns = LessonContent.checks.map { Regexp.new(it[:pattern]) }

    assert patterns.all? { it.match?(solution) }, "a correct solution should pass every criterion"
    assert_not patterns.all? { it.match?(LessonContent::STARTER_CODE) },
               "the starter code should not already pass"
  end

  test "the contribution grid is deterministic and in range" do
    assert_equal LearnerProfile::ACTIVITY_DAYS, LearnerProfile.activity.size
    assert_equal LearnerProfile.activity, LearnerProfile.activity
    assert LearnerProfile.activity.all? { (0..4).cover?(it) }
  end

  test "enrollment percentages are derived, not hardcoded" do
    enrollment = LearnerProfile.enrollments("progress").first

    assert_equal "AI1101", enrollment.code
    assert_equal 32, enrollment.learned_percent
    assert_equal 13, enrollment.applied_percent
  end

  test "the leaderboard marks exactly one row as you" do
    entries = Leaderboard.entries

    assert_equal Leaderboard::FIGURES.size, entries.size
    assert_equal 1, entries.count(&:you?)
    assert_equal 3, entries.count(&:podium?)
    assert_equal (1..entries.size).to_a, entries.map(&:rank)
  end

  test "roster students classify their own standing and last-seen wording" do
    roster = InstructorReport.roster

    assert_predicate roster.first, :on_track?
    assert_predicate roster.last, :behind?
    assert_equal I18n.t("instructor.seen.today"), roster.first.seen_text
    assert_equal I18n.t("instructor.seen.yesterday"), roster[2].seen_text
    assert_equal I18n.t("instructor.seen.days_ago", count: 12), roster.last.seen_text
  end

  test "hard topics escalate with the failure rate" do
    severities = InstructorReport.hard_topics.map { it[:severity] }

    assert_equal %i[ alarm alarm warn notice notice ], severities
  end
end
