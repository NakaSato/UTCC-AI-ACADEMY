# Generates the current course syllabus as a PDF without including learner state.
# The course and syllabus remain the source of truth; this class only owns the
# document boundary and renderer details.
class CourseSyllabusPdf
  FONT_NAME = "Noto Sans Thai"
  FONT_PATH = Rails.root.join("app/assets/fonts/NotoSansThai-Regular.ttf")

  def self.render(course:, locale: I18n.locale)
    I18n.with_locale(locale) { new(course).render }
  end

  def self.filename(course:, locale: I18n.locale)
    "utcc-ai-academy-#{course.code.downcase}-syllabus-#{locale}.pdf"
  end

  def self.outline(course:, locale: I18n.locale)
    I18n.with_locale(locale) do
      Syllabus.modules(Set.new, course.code).map do |mod|
        {
          number: mod.number,
          title: mod.title,
          topics: mod.topics.map do |topic|
            { key: topic.key, name: topic.name, kind: topic.kind,
              minutes: topic.minutes }
          end
        }
      end
    end
  end

  def initialize(course)
    @course = course
  end

  def render
    pdf = Prawn::Document.new(page_size: "A4", margin: 48, compress: false)
    pdf.font_families.update(FONT_NAME => { normal: FONT_PATH.to_s })
    pdf.font(FONT_NAME)

    title = I18n.t("documents.syllabus.title", course: course_title)
    pdf.text title, size: 22
    pdf.move_down 6
    pdf.text course.code, size: 12
    pdf.move_down 18
    pdf.stroke_color "D6D9DE"
    pdf.stroke_horizontal_rule
    pdf.move_down 14

    outline.each do |mod|
      pdf.text "#{mod[:number]}. #{mod[:title]}", size: 15
      pdf.move_down 6

      mod[:topics].each do |topic|
        pdf.text topic_line(topic), size: 11, indent_paragraphs: 12
        pdf.move_down 4
      end

      pdf.move_down 12
    end

    pdf.render
  end

  private
    attr_reader :course

    def course_title
      I18n.t("catalog.courses.#{course.code}.title")
    end

    def outline
      self.class.outline(course:, locale: I18n.locale)
    end

    def topic_line(topic)
      kind = I18n.t("course.kind.#{topic[:kind]}")
      minutes = I18n.t("units.minutes", count: topic[:minutes])
      "#{topic[:name]} · #{kind} · #{minutes}"
    end
end
