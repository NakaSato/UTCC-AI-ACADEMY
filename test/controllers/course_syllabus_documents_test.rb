require "test_helper"

class CourseSyllabusDocumentsTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:one) }

  test "an authenticated learner downloads the selected course syllabus as a PDF" do
    get course_syllabus_url("AI1101", lang: "en")

    assert_response :success
    assert_equal "application/pdf", response.media_type
    assert_match(/attachment; filename="utcc-ai-academy-ai1101-syllabus-en\.pdf"/,
                 response.headers["Content-Disposition"])
    assert response.body.start_with?("%PDF")
    assert_equal "AI Fundamentals syllabus",
                 I18n.with_locale(:en) { I18n.t("documents.syllabus.title", course: "AI Fundamentals") }
    assert_equal "AI Fundamentals",
                 I18n.with_locale(:en) { I18n.t("catalog.courses.AI1101.title") }
  end

  test "the second course document has its own outline" do
    get course_syllabus_url("AI1102", lang: "en")

    assert_response :success
    assert_equal "application/pdf", response.media_type
    assert_equal [ "Python foundations", "Prepare a dataset" ],
                 CourseSyllabusPdf.outline(course: courses(:ai1102), locale: :en).map { |mod| mod[:title] }
    assert_not_includes CourseSyllabusPdf.outline(course: courses(:ai1102), locale: :en).flat_map { |mod| mod[:topics] }.map { |topic| topic[:name] },
                        "What AI is, and actually does"
  end

  test "the requested locale controls document copy" do
    get course_syllabus_url("AI1102", lang: "th")

    assert_response :success
    assert_equal "พื้นฐาน Python",
                 CourseSyllabusPdf.outline(course: courses(:ai1102), locale: :th).first[:title]
  end

  test "unknown and unmodeled courses do not fall back to another syllabus" do
    [ "AI2402", "NOPE" ].each do |code|
      get course_syllabus_url(code, lang: "en")

      assert_response :not_found
      assert_empty response.body
    end
  end

  test "the course page exposes a working syllabus document link" do
    get course_url("AI1102")

    assert_response :success
    assert_select "a[href=?]", course_syllabus_path("AI1102"), text: I18n.t("course.download_syllabus")
  end

  # The other side of the same link, and the reason this test exists: six of the
  # eight courses carry no module rows, so the document answers 404 — correctly,
  # because the syllabus a learner reads on those pages is the default taxonomy
  # standing in until a real curriculum lands. Every one of them offered the
  # download anyway, and a link crawl over the whole app found it.
  test "a course with no curriculum offers no download" do
    assert_not ::Course.find_by!(code: "AI2402").syllabus?

    get course_url("AI2402")

    assert_response :success
    assert_select "a[href=?]", course_syllabus_path("AI2402"), count: 0,
      message: "a button that answers 404 is worse than no button"
  end
end
