# The two edits a teacher may make to their own draft syllabus: what a lesson is
# called, and what order the lessons come in.
#
# Both are only safe because [[SyllabusText]] moved a topic's name off its
# position and onto `topics.key`. Before that, moving one lesson up renamed every
# lesson below it in both languages at once.
#
# `topics.key` keeps the value it was minted with — "1-1" may end up sitting
# third, and that is fine: the key is identity, not a description. It is what
# `/lesson?topic=` carries and what every completion row, prior-knowledge row and
# integrity setting joins by, so a reorder that rewrote keys would detach every
# learner's progress from the lesson they finished.
class SyllabusBuilder
  # A position no lesson holds, used to step out of the way of the unique index
  # on (course_module_id, position) — two rows cannot swap in place.
  PARKED = 0

  attr_reader :course

  def initialize(course)
    @course = course
  end

  # The outline the panel draws: modules in order, each with its topics in order,
  # and both names of each topic so a teacher editing one language cannot blank
  # the other by saving the form.
  def outline
    # Titles read once for the whole syllabus rather than once per module — the
    # panel is the only screen that draws every module and every topic at once.
    titles = Syllabus.modules(Set.new, course.code).to_h { [ it.number, it.title ] }

    course.course_modules.includes(:topics).order(:number).map do |mod|
      { number: mod.number, title: titles[mod.number].to_s,
        topics: mod.topics.sort_by(&:position).map { row_for(it) } }
    end
  end

  # Up or down one place, within the module. Refuses the ends rather than
  # wrapping, and refuses a key that is not this course's.
  def move!(topic_key, direction)
    topic = topic_for(topic_key) or return false
    siblings = topic.course_module.topics.order(:position).to_a
    index = siblings.index { it.id == topic.id }
    target = direction.to_s == "up" ? index - 1 : index + 1
    return false if target.negative? || target >= siblings.size

    swap!(topic, siblings[target])
    true
  end

  # Both languages, every time, and never a delete-back-to-default.
  #
  # LandingText deletes a row that matches the shipped copy so nothing shadows
  # the locale file with a duplicate of itself. That rule cannot hold here: the
  # shipped copy is read *by position*, so "the default" for a topic is whatever
  # lesson happens to sit where this one sits. Deferring to it would put the name
  # back on a footing a reorder can move — which is the bug this class exists to
  # avoid. So a renamed topic is pinned in both languages.
  def rename!(topic_key, names)
    topic = topic_for(topic_key) or return false

    # Every language or none. A payload carrying only one would pin that one and
    # leave the other reading off its position — and the next reorder would then
    # move the unpinned name while the pinned one stayed, so the two languages
    # would be naming different lessons. Half a rename is worse than none.
    wanted = I18n.available_locales.map(&:to_s)
    given = names.slice(*wanted)
    raise ActiveRecord::RecordInvalid, topic unless wanted.all? { given[it].to_s.strip.present? }

    SyllabusText.transaction do
      given.each { |locale, value| SyllabusText.write(SyllabusText.topic_key(topic.key), locale, value, default: nil) }
    end
    Syllabus.reload!
    true
  end

  # A lesson exists because an administrator approved it — this is called from
  # `ApprovalRequest#apply!`, inside that decision's transaction, and from
  # nowhere else. A teacher asks; the queue decides; this writes.
  #
  # Removing a lesson is a *retirement*, never a delete (ADR-0055): the row stays,
  # stops being offered, and stops counting toward a denominator, so a completion
  # and an integrity case can still say which lesson they meant.
  def add_lesson!(module_number:, topic_kind:, minutes:, names:)
    mod = course.course_modules.find_by!(number: module_number.to_i)
    position = (mod.topics.maximum(:position) || 0) + 1

    topic = Topic.create!(course_module: mod, position:, kind: topic_kind.to_s,
                          minutes: minutes.to_i, key: mint_key(mod, position))

    names.slice(*I18n.available_locales.map(&:to_s)).each do |locale, value|
      SyllabusText.write(SyllabusText.topic_key(topic.key), locale, value, default: nil)
    end
    Syllabus.reload!
    topic
  end

  # Putting one back. ADR-0055 left this out and said what it would be when
  # somebody wanted it — a second request kind, not a button — so this is that
  # rather than a reversal of it.
  def restore_lesson!(topic_key)
    topic = topic_for(topic_key)
    return false if topic.nil? || !topic.retired?

    topic.update!(retired_at: nil)
    Syllabus.reload!
    true
  end

  # The other half of the same decision, and it destroys nothing.
  #
  # Called from `ApprovalRequest#apply!` inside the decision's transaction and
  # lock, so the liveness check here closes the window the validation at request
  # time cannot: a lesson retired by one decision cannot be retired again by a
  # request raised before it.
  def retire_lesson!(topic_key)
    topic = topic_for(topic_key)
    return false if topic.nil? || topic.retired?

    topic.update!(retired_at: Time.current)
    Syllabus.reload!
    true
  end

  private
    # `Topic.key_for` derives a key from a position, and a position is re-usable:
    # a module that once had five lessons and now has four would mint "1-5" a
    # second time, and `topics.key` is globally unique. So the derived key is a
    # starting point and the first free one wins — the key still reads like a
    # position, and is still only identity.
    def mint_key(mod, position)
      candidate = position
      candidate += 1 while Topic.exists?(key: Topic.key_for(mod.number, candidate, course_code: course.code))
      Topic.key_for(mod.number, candidate, course_code: course.code)
    end

    # Scoped to this course, so a key from another course's syllabus is simply
    # not found rather than edited.
    def topic_for(topic_key)
      Topic.joins(:course_module)
           .find_by(key: topic_key.to_s, course_modules: { course_id: course.id })
    end

    # Pin first, then move.
    #
    # A row on `topics.key` is what holds a name still, and a topic nobody has
    # renamed has no row: its name is whatever the locale file says at its
    # position, so swapping two untouched lessons still swaps their names. So the
    # swap writes down what both lessons are called — in every language — before
    # it moves them. Only two positions change, so only two names are at risk.
    #
    # This is the moment a course stops deferring to the shipped copy, and it is
    # the honest place for it: the first reorder is exactly when position stops
    # being a description of the syllabus.
    def swap!(topic, other)
      Topic.transaction do
        [ topic, other ].each { pin_name!(it) }

        here, there = topic.position, other.position
        topic.update!(position: PARKED)
        other.update!(position: here)
        topic.update!(position: there)
      end
      Syllabus.reload!
    end

    def pin_name!(topic)
      key = SyllabusText.topic_key(topic.key)

      I18n.available_locales.each do |locale|
        next if SyllabusText.for(key, locale).present?

        name = I18n.with_locale(locale) { Syllabus.topic_name(topic.key, course.code) }
        SyllabusText.write(key, locale, name, default: nil) if name.present?
      end
    end

    def row_for(topic)
      key = SyllabusText.topic_key(topic.key)

      { key: topic.key, kind: topic.kind, minutes: topic.minutes, position: topic.position,
        retired: topic.retired?,
        names: I18n.available_locales.to_h do |locale|
          [ locale.to_s, I18n.with_locale(locale) { Syllabus.topic_name(topic.key, course.code) } ]
        end,
        overridden: I18n.available_locales.any? { SyllabusText.for(key, it).present? } }
    end
end
