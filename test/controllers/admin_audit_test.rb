require "test_helper"

# What the console leaves behind. Every case here drives the real endpoint
# rather than calling AuditEvent directly, because the thing worth protecting is
# that the controller and the log cannot drift apart: an action that stops
# recording, or a new one that never starts, fails here.
class AdminAuditTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:admin) }

  test "a role grant is logged, named and marked worth watching" do
    patch admin_user_url(users(:student)), params: { role: "instructor" }

    event = AuditEvent.sole

    assert_equal("role_changed", event.action)
    assert_equal(users(:admin), event.user)
    assert_equal(:warn, event.level)
    assert_equal(I18n.t("audit.role_changed", name: users(:student).name,
                                              role: I18n.t("admin.roles.instructor")), event.text)
  end

  # A rejected action is not something that happened.
  test "nothing is logged when the action fails" do
    patch admin_user_url(users(:student)), params: { role: "wizard" }
    patch admin_user_url(users(:admin)), params: { role: "student" }
    post admin_sections_url, params: { course_code: "AI1101", code: "", term: "" }
    post admin_landing_cards_url, params: { collection: "topics", title: { th: "" } }

    assert_empty(AuditEvent.all)
  end

  test "the section writes are logged, and removing somebody is the one worth watching" do
    section = sections(:ba_2)

    post admin_sections_url, params: { course_code: "AI1101", code: "BA-9", term: "1/2569" }
    patch admin_section_url(section), params: { instructor_id: users(:instructor).id }
    post admin_enrol_url(section), params: { student_id: users(:two).student_id }
    delete admin_unenrol_url(section, users(:two))

    assert_equal(%w[ section_created section_updated enrolled unenrolled ],
                 AuditEvent.order(:id).map(&:action))
    assert_equal(%i[ info info info warn ], AuditEvent.order(:id).map(&:level))
  end

  # Re-submitting the enrolment form must not ping the student a second time,
  # and must not log a second time either.
  test "re-enrolling somebody already in the section logs nothing new" do
    section = sections(:ba_2)
    post admin_enrol_url(section), params: { student_id: users(:two).student_id }

    assert_no_difference -> { AuditEvent.count } do
      post admin_enrol_url(section), params: { student_id: users(:two).student_id }
    end
  end

  test "editing the landing page is logged once per save, naming the group" do
    patch admin_landing_url, params: { group: "hero", text: { "hero.headline" => { th: "เรียน AI" } } }

    assert_equal("landing_saved", AuditEvent.sole.action)
    assert_includes(AuditEvent.sole.text, I18n.t("admin.landing.sections.hero"))
  end

  test "adding and deleting a card are logged, and the deletion names what went" do
    post admin_landing_cards_url, params: { collection: "topics", title: { en: "Agents" } }
    card = LandingCard.in_order("topics").last
    delete admin_landing_card_url(card)

    added, removed = AuditEvent.order(:id).to_a

    assert_equal(%w[ card_added card_removed ], [ added.action, removed.action ])
    assert_equal(:warn, removed.level)
    # Read before the destroy — afterwards the copy that named it is gone.
    assert_includes(removed.text, "Agents")
  end

  # Reordering changes neither what exists nor who can do what, and it is the
  # noisiest control on the screen.
  test "reordering a card is deliberately not logged" do
    assert_no_difference -> { AuditEvent.count } do
      patch move_admin_landing_card_url(LandingCard.in_order("topics").second, dir: :up)
    end
  end

  test "the integrity decisions are logged, and escalating is the one worth watching" do
    # Already in BA-2 by fixture, which is what gives escalation an instructor
    # to escalate to.
    student = users(:student)
    ProctorEvent.create!(user: student, course: courses(:ai1101), topic: topics(:topic_1_1),
                         kind: "blur", occurred_at: Time.current)

    post notify_integrity_case_url(student)
    post escalate_integrity_case_url(student)
    post close_integrity_case_url(student)

    assert_equal(%w[ integrity_notified integrity_escalated integrity_closed ],
                 AuditEvent.order(:id).map(&:action))
    assert_equal(%i[ info warn info ], AuditEvent.order(:id).map(&:level))
  end

  test "the tab renders the rows and the level chips filter them" do
    patch admin_user_url(users(:student)), params: { role: "instructor" }
    post admin_enrol_url(sections(:ba_2)), params: { student_id: users(:two).student_id }

    get admin_url(tab: :audit)
    assert_response :success
    assert_select "main", text: /#{Regexp.escape(users(:admin).name)}/

    get admin_url(tab: :audit, level: :warn)
    assert_select "main", text: /#{Regexp.escape(I18n.t("audit.role_changed", name: users(:student).name, role: I18n.t("admin.roles.instructor")))}/
    assert_select "main", text: /#{Regexp.escape(I18n.t("audit.enrolled", name: users(:two).name, label: sections(:ba_2).label))}/, count: 0
  end

  test "a console nobody has used yet says so rather than showing nothing" do
    get admin_url(tab: :audit)

    assert_select "main", text: /#{Regexp.escape(I18n.t("admin.audit.empty"))}/
  end

  test "a student cannot read the log" do
    sign_in_as users(:student)
    get admin_url(tab: :audit)

    assert_redirected_to root_path
    assert_equal(I18n.t("flash.forbidden"), flash[:alert])
  end
end
