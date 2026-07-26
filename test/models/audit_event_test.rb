require "test_helper"

# The row is an action and its interpolations, never a sentence. Everything here
# is a consequence of that: the level is derived, the line reads in whichever
# language it is being read in, and an action nothing performs cannot be stored.
class AuditEventTest < ActiveSupport::TestCase
  setup { Current.session = users(:admin).sessions.create! }

  test "the actor is whoever is signed in, not an argument" do
    AuditEvent.record("integrity_closed", name: "ทดสอบ")

    assert_equal(users(:admin), AuditEvent.sole.user)
  end

  # A rake task or a seed has no actor to name, and should not blow up reaching
  # something that wants one.
  test "nothing is recorded when nobody is acting" do
    Current.session = nil

    assert_no_difference -> { AuditEvent.count } do
      AuditEvent.record("integrity_closed", name: "ทดสอบ")
    end
  end

  test "an action nothing performs is not an action" do
    event = AuditEvent.new(user: users(:admin), action: "deleted_everything")

    assert_not(event.valid?)
    assert_includes(event.errors.attribute_names, :action)
  end

  # Which entries are worth a second look is a display convention, so changing
  # one should not need a backfill.
  test "the level is derived from the action rather than stored" do
    assert_not_includes(AuditEvent.column_names, "level")
    assert_equal(:warn, AuditEvent.new(action: "role_changed").level)
    assert_equal(:info, AuditEvent.new(action: "enrolled").level)
  end

  test "the line reads in the reader's language, not the actor's" do
    I18n.with_locale(:th) { AuditEvent.record("role_changed", name: "สมชาย", role: "instructor") }
    event = AuditEvent.sole

    I18n.with_locale(:en) do
      assert_equal(I18n.t("audit.role_changed", name: "สมชาย", role: I18n.t("admin.roles.instructor")), event.text)
    end
    I18n.with_locale(:th) { assert_includes(event.text, I18n.t("admin.roles.instructor", locale: :th)) }
  end

  test "a landing group is stored as its key and named in the reader's language" do
    AuditEvent.record("landing_saved", group: "tracks")

    I18n.available_locales.each do |locale|
      I18n.with_locale(locale) do
        assert_includes(AuditEvent.sole.text, I18n.t("admin.landing.sections.tracks"))
      end
    end
  end

  # Filtered in SQL so RECENT caps what survives the filter. Folded in Ruby it
  # would cap first and the warn tab would come back short.
  test "the level filter runs before the cap, not after it" do
    (AuditEvent::RECENT + 1).times { AuditEvent.record("enrolled", name: "x", label: "y") }
    AuditEvent.record("role_changed", name: "x", role: "admin")

    warned = AuditEvent.at_level(:warn).newest_first.limit(AuditEvent::RECENT)

    assert_equal(1, warned.size)
    assert_equal(AuditEvent::RECENT, AuditEvent.at_level(:info).newest_first.limit(AuditEvent::RECENT).size)
    assert_equal(AuditEvent.count, AuditEvent.at_level(:all).count)
  end

  test "every recordable action has a sentence in both locales" do
    I18n.available_locales.each do |locale|
      AuditEvent::ACTIONS.each do |action|
        copy = I18n.t("audit.#{action}", locale:, default: nil)

        assert(copy.present?, "#{action} in #{locale}")
      end
    end
  end

  test "every action worth watching is an action" do
    assert_empty(AuditEvent::WARN - AuditEvent::ACTIONS)
  end
end
