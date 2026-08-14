require "test_helper"

# A route can exist and still be a 500 waiting to happen. On 2026-08-12 one did:
# `/company/:slug/internship_programs/:id/applications` was routed to an action
# with no template at all, and the only test touching it passed because it
# asserted a 404 for an outsider — a refusal that happens before rendering. An
# authorized reader would have met ActionView::MissingTemplate. Nothing linked
# to it, so nobody found out.
#
# This closes that class rather than that instance.
class RouteReachabilityTest < ActiveSupport::TestCase
  # Engine and framework routes are not ours to answer for.
  FOREIGN = /\A(rails|active_storage|action_mailbox|turbo)/

  # Every GET route that renders no template of its own, and why. A new entry
  # here should be a deliberate sentence, not a shrug: the alternative is the
  # missing-template error above, which nothing catches until somebody visits.
  WITHOUT_TEMPLATE = {
    "policies#privacy" => "shares policies/show with #terms — both documents are the same shape",
    "policies#terms" => "shares policies/show with #privacy",
    "notifications#bell" => "renders the bell partial the header frame comes back for, not a page",
    "course_documents#syllabus" => "send_data: the syllabus PDF",
    "instructor#grades" => "send_data: the section's grades as CSV",
    "admin#report" => "send_data: one of the console Overview's three CSV reports",
    "academic_posts#export" => "send_data: the post as a standalone HTML document",
    "recruitment/candidate_profiles#export" => "send_data: the candidate's own profile as JSON",
    "internship_request_resumes#show" => "send_data: a shared résumé, always as an attachment (SPEC-0041)",
    "internship_deliverables#download" => "send_data: a student's deliverable, always as an attachment"
  }.freeze

  def app_routes
    Rails.application.routes.routes.filter_map do |route|
      controller = route.defaults[:controller]
      action = route.defaults[:action]
      next if controller.blank? || action.blank? || controller.match?(FOREIGN)

      { controller:, action:, verb: route.verb.to_s, path: route.path.spec.to_s }
    end
  end

  test "every route resolves to a controller action that exists" do
    missing = app_routes.filter_map do |route|
      klass = "#{route[:controller]}_controller".camelize.safe_constantize
      next "#{route[:path]} → #{route[:controller]} (no such controller)" if klass.nil?

      unless klass.action_methods.include?(route[:action]) || klass.method_defined?(route[:action])
        "#{route[:path]} → #{route[:controller]}##{route[:action]}"
      end
    end

    assert_empty missing, "these routes lead nowhere:\n#{missing.join("\n")}"
  end

  test "every GET route renders a template, or says in writing why it does not" do
    undeclared = app_routes.filter_map do |route|
      next unless route[:verb].include?("GET")

      klass = "#{route[:controller]}_controller".camelize.safe_constantize
      next if klass.nil?

      key = "#{route[:controller]}##{route[:action]}"
      next if WITHOUT_TEMPLATE.key?(key)
      next if template_for?(klass, route[:action])

      "#{route[:verb]} #{route[:path]} → #{key}"
    end

    assert_empty undeclared, <<~MESSAGE
      These GET routes render no template and are not in WITHOUT_TEMPLATE:

      #{undeclared.join("\n")}

      If the action sends data or renders a partial, add it there with the
      reason. If it does not, it is a missing-template error waiting for its
      first authorized visitor.
    MESSAGE
  end

  # The list is a record of deliberate exceptions, so it has to stay true: an
  # entry that grows a template is an entry nobody needs any more.
  test "nothing in the exception list has quietly grown a template" do
    stale = WITHOUT_TEMPLATE.keys.select do |key|
      controller, action = key.split("#")
      klass = "#{controller}_controller".camelize.safe_constantize
      klass && template_for?(klass, action)
    end

    assert_empty stale, "these now render a template and can leave WITHOUT_TEMPLATE: #{stale.join(', ')}"
  end

  private
    def template_for?(klass, action)
      prefixes = klass.ancestors.take_while { it != ActionController::Base }
                      .filter_map { it.name&.sub(/Controller\z/, "")&.underscore }

      ActionView::LookupContext.new(klass.view_paths).exists?(action, prefixes, false)
    end
end
