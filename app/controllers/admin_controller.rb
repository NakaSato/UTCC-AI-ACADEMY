class AdminController < ApplicationController
  allow_only :admin

  def show
    @tab = AdminConsole.tab_for(params[:tab])

    case @tab
    in :users
      # Both filters are whitelist-or-default; the search is a plain substring
      # over the two columns the roster shows.
      @role = AdminConsole.role_filter(params[:role])
      @query = FeatureSetting.enabled?(:search) ? params[:q].to_s.strip : ""

      @users = User.order(:role, :name)
      @users = @users.where(role: @role) unless @role == :all
      if @query.present?
        needle = "%#{User.sanitize_sql_like(@query)}%"
        # All three identifier columns, because a console account has no student
        # ID and would otherwise be unfindable by anything but its name.
        @users = @users.where(
          "name LIKE :q OR student_id LIKE :q OR username LIKE :q OR email_address LIKE :q", q: needle
        )
      end
      # For the create-account form's organization select — a company account is
      # an account plus a membership, so it needs somewhere to be a member of.
      @organizations = Organization.active.order(:name)
    in :sections then load_sections
    # Which group of the landing page is open is the URL, like every other bit
    # of screen state; an unknown one simply opens nothing.
    in :landing then @group = Landing.group_for(params[:group])&.key
    in :integrity then @cases = Proctoring.cases
    in :audit
      @level = AdminConsole.level_filter(params[:level])
      # Filtered in SQL, so the cap is what survives the filter rather than what
      # went into it.
      @events = AuditEvent.at_level(@level).newest_first.includes(:user).limit(AuditEvent::RECENT)
    in :courses then @query = FeatureSetting.enabled?(:search) ? params[:q].to_s.strip : ""
    in :queue then nil
    else nil
    end
  end

  def update_course_state
    course = Course.find(params[:id])
    ApprovalRequest.create_course_lifecycle!(course:, requester: Current.user,
                                             from_state: params[:from], to_state: params[:state], note: params[:note])

    redirect_to admin_path(tab: :queue), notice: t("flash.approval_requested", course: course.code)
  rescue ActiveRecord::RecordInvalid => invalid
    redirect_to admin_path(tab: :courses), alert: invalid.record.errors.full_messages.to_sentence
  end

  def decide_approval
    request = ApprovalRequest.find(params[:id])
    request.decide!(actor: Current.user, outcome: params[:outcome], note: params[:note])

    redirect_to admin_path(tab: :queue), notice: t("flash.approval_decided")
  rescue ActiveRecord::RecordInvalid
    redirect_to admin_path(tab: :queue), alert: t("flash.approval_invalid")
  end

  def update_feature_setting
    key = params[:key].to_s
    enabled = FeatureSetting.parse_boolean(params[:enabled])

    unless FeatureSetting.definition(key) && !enabled.nil?
      redirect_to admin_path(tab: :features), alert: t("flash.feature_setting_invalid")
      return
    end

    previous = FeatureSetting.enabled?(key)
    FeatureSetting.transaction do
      FeatureSetting.update!(key:, enabled:, expected_lock_version: params[:lock_version])
      AuditEvent.record("feature_setting_changed", key:, from_state: previous ? "on" : "off",
                        to_state: enabled ? "on" : "off")
    end

    redirect_to admin_path(tab: :features), notice: t("flash.feature_setting_changed",
                                                         name: t("admin.features.keys.#{key}"),
                                                         state: t("admin.features.state.#{enabled ? :on : :off}"))
  rescue ActiveRecord::StaleObjectError
    redirect_to admin_path(tab: :features), alert: t("flash.feature_setting_stale")
  rescue ActiveRecord::RecordInvalid
    redirect_to admin_path(tab: :features), alert: t("flash.feature_setting_invalid")
  end

  # The three section writes. Each answers with a redirect back to the tab and
  # a flash, like #update below — no JSON, no partial responses. Validation
  # failures surface as the model's own messages, so the invariants (staff-only
  # instructor, student-only roster) read the same here as in the tests.
  def create_section
    section = Section.new(course: Course.find_by(code: params[:course_code].to_s),
                          code: params[:code].to_s.strip, term: params[:term].to_s.strip,
                          instructor: find_staff(params[:instructor_id]))

    Section.transaction do
      section.save!
      AuditEvent.record("section_created", label: section.label)
    end

    redirect_to admin_path(tab: :sections, section: section.id),
                notice: t("flash.section_created", label: section.label)
  rescue ActiveRecord::RecordInvalid => invalid
    redirect_to admin_path(tab: :sections), alert: invalid.record.errors.full_messages.to_sentence
  end

  def update_section
    section = Section.find(params[:id])

    Section.transaction do
      section.update!(instructor: find_staff(params[:instructor_id]))
      # The label and no more: "unassigned" would have to be stored as a
      # translated phrase, and who teaches a section is on the Sections tab.
      AuditEvent.record("section_updated", label: section.label)
    end

    redirect_to admin_path(tab: :sections, section: section.id),
                notice: t("flash.section_updated", label: section.label)
  rescue ActiveRecord::RecordInvalid => invalid
    redirect_to admin_path(tab: :sections, section: section.id),
                alert: invalid.record.errors.full_messages.to_sentence
  end

  def enrol
    section = Section.find(params[:id])
    student = User.find_by(student_id: params[:student_id].to_s.strip.downcase)

    if student.nil?
      redirect_to admin_path(tab: :sections, section: section.id), alert: t("flash.student_missing")
      return
    end

    enrollment = Enrollment.find_or_initialize_by(section:, user: student)
    fresh = enrollment.new_record?

    unless enrollment.persisted?
      Section.transaction do
        enrollment.save!
        # Only a new enrolment is news — re-submitting the form must not ping, and
        # must not log a second time either.
        if fresh
          Notification.notify(student, "enrolled", label: section.label)
          AuditEvent.record("enrolled", name: student.name, label: section.label)
        end
      end
    end

    redirect_to admin_path(tab: :sections, section: section.id),
                notice: t("flash.enrolled", name: student.name, label: section.label)
  rescue ActiveRecord::RecordInvalid => invalid
    redirect_to admin_path(tab: :sections, section: section.id),
                alert: invalid.record.errors.full_messages.to_sentence
  end

  def unenrol
    section = Section.find(params[:id])
    enrollment = section.enrollments.find_by!(user_id: params[:user_id])
    Section.transaction do
      enrollment.destroy!
      AuditEvent.record("unenrolled", name: enrollment.user.name, label: section.label)
    end

    redirect_to admin_path(tab: :sections, section: section.id),
                notice: t("flash.unenrolled", name: enrollment.user.name, label: section.label)
  end

  # The landing page's copy, in both languages at once.
  #
  # Whitelist-driven rather than strong-params, like every other param in this
  # controller: `Landing.editable_keys` decides what can be read out of the
  # request at all, so a key posted for a string the page does not render is
  # never looked at and cannot become a row.
  #
  # One form posts one group, so a field the params do not carry was not on the
  # form and is left alone — only a field that was there and came back empty is
  # a deletion. The whole save is one transaction: a level that is not a level
  # must not leave half a group rewritten.
  #
  # A card's own attributes — a track's level and weeks, an event's date — ride
  # on the same form as its copy, because they are the same card.
  def update_landing
    group = Landing.group_for(params[:group])

    LandingText.transaction do
      Landing.editable_keys.each do |key|
        I18n.available_locales.each do |locale|
          value = posted(:text, key, locale.to_s)
          LandingText.write(key, locale, value) unless value.nil?
        end
      end

      group&.cards&.each { save_attributes(it.record) }
      # One entry per save, naming the group — not one per field, which would be
      # a hundred lines for a page nobody rewrote a hundred strings of.
      AuditEvent.record("landing_saved", group: group&.key.to_s)
    end

    redirect_to landing_tab(group), notice: t("flash.landing_saved")
  rescue ActiveRecord::RecordInvalid => invalid
    redirect_to landing_tab(group), alert: invalid.record.errors.full_messages.to_sentence
  end

  # A new card is created with its titles, so it is never born nameless — the
  # editor names a card by its own title, and one with neither would be a row an
  # admin could only tell apart by its slug.
  def create_card
    collection = params[:collection].to_s
    return redirect_to landing_tab(nil), alert: t("flash.card_invalid") unless
      LandingCard::COLLECTIONS.include?(collection)

    titles = I18n.available_locales.to_h { [ it, posted(:title, it.to_s).to_s.strip ] }
    # One language is enough — the page falls back to whichever has copy — but
    # neither is a card nobody can tell from its slug.
    return redirect_to landing_tab(group_of(collection)), alert: t("flash.card_untitled") if
      titles.values.all?(&:blank?)

    copy_field = collection == "faqs" ? "q" : "title"
    card = LandingCard.new(collection:, key: LandingCard.key_for(collection, titles[:en], titles[:th]))

    LandingCard.transaction do
      card.save!
      titles.each { |locale, title| LandingText.write("#{card.prefix}.#{copy_field}", locale, title) }
      AuditEvent.record("card_added", group: group_of(collection)&.key, name: card.label)
    end

    Landing.forget_cards
    redirect_to landing_tab(group_of(collection)), notice: t("flash.card_added")
  rescue ActiveRecord::RecordInvalid => invalid
    redirect_to landing_tab(group_of(collection)), alert: invalid.record.errors.full_messages.to_sentence
  end

  # A no-op at either end: the button is not rendered there, and a request that
  # arrives anyway is not worth a flash of its own.
  def move_card
    card = LandingCard.find(params[:id])
    card.move(params[:dir]) if %w[ up down ].include?(params[:dir].to_s)
    Landing.forget_cards

    redirect_to landing_tab(group_of(card.collection)), notice: t("flash.card_moved")
  end

  # Destroying a card takes its copy with it — see LandingCard's after_destroy.
  def destroy_card
    card = LandingCard.find(params[:id])
    # Read before the destroy: afterwards the copy that named it is gone too.
    name = card.label
    LandingCard.transaction do
      card.destroy!
      LandingText.forget
      AuditEvent.record("card_removed", group: group_of(card.collection)&.key, name:)
    end

    Landing.forget_cards
    LandingText.forget

    redirect_to landing_tab(group_of(card.collection)), notice: t("flash.card_removed")
  end

  # "Notify student": the learner hears their case was flagged, in their own
  # language when they read it.
  def notify_case
    subject = case_subject or return
    user, course = subject
    Notification.notify(user, "integrity_notice", course: course.code)
    AuditEvent.record("integrity_notified", name: user.name, course: course.code)

    redirect_to admin_path(tab: :integrity), notice: t("flash.case_notified", name: user.name)
  end

  # "Escalate": the instructor of the student's section for that course hears.
  # No section or no instructor is a flash, not a guess at someone else.
  def escalate_case
    subject = case_subject or return
    user, course = subject
    instructor = user.sections.find_by(course:)&.instructor

    if instructor.nil?
      redirect_to admin_path(tab: :integrity), alert: t("flash.no_instructor", name: user.name)
    else
      Notification.notify(instructor, "integrity_escalated", name: user.name, course: course.code)
      AuditEvent.record("integrity_escalated", name: user.name, to: instructor.name, course: course.code)
      redirect_to admin_path(tab: :integrity), notice: t("flash.case_escalated", name: instructor.name)
    end
  end

  # Closing a case is stamping the learner's unreviewed events — there is no
  # case row, so there is nothing else to write. New events open a new case.
  def close_case
    user = User.find(params[:user_id])
    ProctorEvent.unreviewed.where(user:).update_all(reviewed_at: Time.current, updated_at: Time.current)
    AuditEvent.record("integrity_closed", name: user.name)

    redirect_to admin_path(tab: :integrity), notice: t("flash.integrity_closed", name: user.name)
  end

  # The only way a console account comes into existence. Sign-up produces
  # learners and nothing else, and an organization invitation can only reach an
  # account that already exists, so without this an instructor or a company
  # member could only be made from a Rails console.
  #
  # No student ID is asked for and none is set: the account is named by its
  # username, its email address, or both — see User#is_identifiable.
  def create_console_account
    access = params[:access].to_s
    unless AdminConsole::CONSOLE_ACCESS.include?(access)
      redirect_to admin_path(tab: :users), alert: t("flash.console_account_invalid")
      return
    end

    organization = Organization.active.find_by(id: params[:organization_id]) if access == "company"
    if access == "company" && organization.nil?
      redirect_to admin_path(tab: :users), alert: t("flash.console_account_no_organization")
      return
    end

    # Generated, never chosen: the admin relays it once and the account owner
    # changes it on /profile. Only the digest is stored.
    password = User.generate_temporary_password
    user = User.new(console_account_params)
    user.role = access if User::ROLES.include?(access)
    user.password = password

    User.transaction do
      user.save!
      organization&.memberships&.create!(user:, role: params[:membership_role].to_s, status: "active")
      AuditEvent.record("console_account_created", identifier: user.identifier, name: user.name, access:)
    end

    redirect_to admin_path(tab: :users),
                notice: t("flash.console_account_created", identifier: user.identifier, password:)
  rescue ActiveRecord::RecordInvalid => invalid
    redirect_to admin_path(tab: :users), alert: invalid.record.errors.full_messages.to_sentence
  end

  def update
    user = User.find(params[:id])

    # An admin cannot change their own role. Only an admin reaches this action, so
    # that single rule is what guarantees the last admin cannot demote the site
    # into having none.
    if user == Current.user
      redirect_to admin_path, alert: t("flash.role_self")
    elsif user.update(role: params[:role])
      # The role key, not the sentence — the notification and the audit line both
      # name the role in the reader's language when they are read, not the
      # granter's when it was given.
      Notification.notify(user, "role_changed", role: user.role)
      AuditEvent.record("role_changed", name: user.name, role: user.role)
      redirect_to admin_path,
                  notice: t("flash.role_changed", name: user.name, role: t("admin.roles.#{user.role}"))
    else
      redirect_to admin_path, alert: t("flash.role_invalid")
    end
  end
  private
    # :role is absent on purpose and must stay absent — the access level comes
    # from the whitelisted `access` param, so a posted role cannot mint an admin
    # by a name the form never offered. :student_id is absent for the same
    # reason as on sign-up, inverted: this screen makes accounts that have none.
    def console_account_params
      params.expect(console_account: [ :name, :username, :email_address ])
    end

    # One posted field, or nil where the form did not carry it. Dug by hand
    # rather than with `params.dig`, which raises when a request posts a string
    # where the form posts a hash — and anything but a string is not an answer.
    def posted(scope, *path)
      value = path.reduce(params[scope]) { |node, key| node.is_a?(ActionController::Parameters) ? node[key] : nil }
      value if value.is_a?(String)
    end

    def landing_tab(group) = admin_path(tab: :landing, group: group&.key)

    def group_of(collection) = Landing.groups.find { it.collection == collection }

    # A card's own attributes, where the form carried them. Blank is a real
    # answer for both: no week count means the track is open-ended, and no date
    # means the event recurs rather than happens once.
    def save_attributes(card)
      level = posted(:card, card.id.to_s, "level")
      weeks = posted(:card, card.id.to_s, "weeks")
      starts_on = posted(:card, card.id.to_s, "starts_on")

      changes = {}
      changes[:level] = level if level
      changes[:weeks] = weeks.presence if weeks
      changes[:starts_on] = starts_on.presence if starts_on

      card.update!(changes) if changes.any?
    end

    def load_sections
      @sections = Section.includes(:course, :instructor).order(:id).to_a
      # Selection is by lookup, so an unknown id falls back rather than raises.
      @selected = @sections.find { it.id == params[:section].to_i } || @sections.first
      @staff = User.where(role: %w[ instructor admin ]).order(:name)
    end

    # A case is a learner's unreviewed events; acting on one that closed under
    # you is a flash, not a crash.
    def case_subject
      user = User.find(params[:user_id])
      event = ProctorEvent.unreviewed.where(user:).newest_first.first

      if event.nil?
        redirect_to admin_path(tab: :integrity), alert: t("flash.case_gone")
        return nil
      end

      [ user, event.course ]
    end

    # The instructor select posts an id; anything that is not a staff member's
    # resolves to nil, and the model rejects a non-staff assignment anyway —
    # this just keeps the common case from round-tripping an error.
    def find_staff(id)
      id.present? ? User.where(role: %w[ instructor admin ]).find_by(id:) : nil
    end
end
