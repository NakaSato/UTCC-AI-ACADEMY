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

  # Every one of these joins a Ruby array to a locale array BY INDEX. A row
  # added on one side and not the other shifts every label after it, silently,
  # in one locale only — which is exactly what these lengths catch.
  test "index-joined placeholder rows line up with their copy in both locales" do
    I18n.available_locales.each do |locale|
      I18n.with_locale(locale) do
        {
          "course.modules" => Syllabus::ENTRIES,
          "lesson.theory.blocks" => LessonContent::BLOCKS,
          "admin.features.groups" => AdminConsole::FLAG_GROUPS,
          "admin.overview.stats" => AdminConsole::STATS,
          "admin.overview.adoption" => AdminConsole::ADOPTION,
          "admin.overview.health" => AdminConsole::HEALTH,
          "admin.courses.rows" => AdminConsole::COURSES,
          "admin.queue.rows" => AdminConsole::QUEUE_KINDS,
          "admin.audit.rows" => AdminConsole::AUDIT_LEVELS
        }.each do |key, rows|
          assert_equal rows.size, I18n.t(key).size, "#{key} in #{locale}"
        end

        assert_equal(
          AdminConsole::ACTIVITY_COUNT, I18n.t("admin.overview.activity").size, "activity in #{locale}"
        )

        # The groups nest, so their item counts have to agree row by row too.
        AdminConsole::FLAG_GROUPS.each_with_index do |items, index|
          assert_equal items.size, I18n.t("admin.features.groups")[index][:items].size,
                       "feature group #{index} in #{locale}"
        end
      end
    end
  end

  test "every placeholder flag and course row resolves its copy in both locales" do
    I18n.available_locales.each do |locale|
      I18n.with_locale(locale) do
        AdminConsole.flags.each do |flag|
          assert flag.name.present?, "#{flag.key} has no #{locale} name"
          assert flag.desc.present?, "#{flag.key} has no #{locale} description"
        end

        AdminConsole.courses.each do |course|
          assert course.name.present?, "#{course.code} has no #{locale} name"
        end

        LessonContent.blocks.each do |block|
          assert block.value.present?, "block #{block.position} has no #{locale} copy"
        end
      end
    end
  end

  test "a draft course is the one with no students" do
    drafts = AdminConsole.courses.select(&:draft?)

    assert_equal [ "AI2204" ], drafts.map(&:code)
    assert(AdminConsole.courses.reject(&:draft?).all? { it.students.positive? })
  end

  test "the integrity band follows the score" do
    assert_equal :clean, Proctoring.band_for(Proctoring::START_SCORE)
    assert_equal :clean, Proctoring.band_for(85)
    assert_equal :review, Proctoring.band_for(84)
    assert_equal :review, Proctoring.band_for(60)
    assert_equal :risk, Proctoring.band_for(59)
    assert_equal :risk, Proctoring.band_for(0)
  end

  # The controller looks each incident up by kind, so a weight with no sentence
  # behind it would log an event the sidebar could not name.
  test "every proctoring weight has copy in both locales" do
    I18n.available_locales.each do |locale|
      I18n.with_locale(locale) do
        assert_equal Proctoring::WEIGHTS.keys.sort, I18n.t("lesson.proctor.events").keys.sort

        Proctoring.event_copy.each do |event|
          assert event[:text].present?, "#{event[:kind]} has no #{locale} sentence"
          assert event[:weight].positive?
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

  # The catalog on its own knows no learner, so every course reads as unstarted.
  # Progress arrives through CourseCatalog.for — see LearnerProgressTest.
  test "the catalog without a learner reports no progress" do
    assert CourseCatalog.all.none?(&:started?)
    assert CourseCatalog.all.all? { it.percent.zero? }
    assert CourseCatalog.all.all? { it.topics.positive? },
           "every course needs a topic count to be the denominator of a progress bar"
  end

  test "every course code is unique and every topic key resolves" do
    assert_equal CourseCatalog.codes.uniq, CourseCatalog.codes

    Syllabus.topic_keys.each do |key|
      assert_operator Syllabus.topic_minutes(key), :>, 0, "#{key} has no duration"
      assert_predicate Syllabus.topic_name(key), :present?, "#{key} has no name"
    end
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

  test "syllabus pairs each topic with its own key, kind and duration" do
    modules = Syllabus.modules

    assert_equal Syllabus::ENTRIES.size, modules.size
    modules.each_with_index do |mod, index|
      assert_equal index + 1, mod.number
      assert_equal Syllabus::ENTRIES[index][1].size, mod.topics.size
      assert mod.title.present?
      mod.topics.each_with_index do |topic, position|
        assert topic.name.present?
        assert_equal Syllabus.topic_key(mod.number, position + 1), topic.key
      end
    end

    supervised = modules[1].topics[2]
    assert_equal "Supervised vs. Unsupervised", supervised.name
    assert_equal I18n.t("course.kind.mix"), supervised.kind_name
    assert_predicate supervised, :applied?
  end

  # Status is derived from what a learner has finished, so with nothing finished
  # the first module is current and everything after it is locked.
  test "module status follows progress rather than a written value" do
    fresh = Syllabus.modules

    assert_predicate fresh.first, :current?
    assert fresh.drop(1).all?(&:locked?)
    assert_not_predicate fresh.first.topics.first, :done?

    done_first = Syllabus.modules(Syllabus.keys_in(1).to_set)
    assert_predicate done_first[0], :done?
    assert_predicate done_first[1], :current?
    assert done_first[0].topics.all?(&:done?)

    all_done = Syllabus.modules(Syllabus.topic_keys.to_set)
    assert all_done.all?(&:done?)
    assert_nil Syllabus.current_module_number(Syllabus.topic_keys.to_set)
  end

  test "a topic is unlocked only up to the module a learner has reached" do
    none = Set.new

    assert Syllabus.unlocked?(Syllabus.keys_in(1).last, none)
    assert_not Syllabus.unlocked?(Syllabus.keys_in(2).first, none)
    assert_not Syllabus.unlocked?("99-9", none), "a key outside the syllabus is never unlocked"

    assert Syllabus.unlocked?(Syllabus.keys_in(2).first, Syllabus.keys_in(1).to_set)
    assert Syllabus.unlocked?(Syllabus.topic_keys.last, Syllabus.topic_keys.to_set)
  end

  test "topic_after walks the syllabus in reading order and stops at the end" do
    assert_equal Syllabus.topic_keys[1], Syllabus.topic_after(Syllabus.topic_keys.first)
    # Across a module boundary, not just within one.
    assert_equal Syllabus.keys_in(2).first, Syllabus.topic_after(Syllabus.keys_in(1).last)
    assert_nil Syllabus.topic_after(Syllabus.topic_keys.last)
    assert_nil Syllabus.topic_after("99-9")
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
