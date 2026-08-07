class PriorKnowledgesController < ApplicationController
  before_action :set_topic_context

  def create
    return redirect_with_alert unless valid_request?

    PriorKnowledge.mark(user: Current.user, course: @course, topic: @topic)
    redirect_to_map(notice: t("flash.prior_knowledge_marked"))
  rescue ActiveRecord::RecordInvalid
    redirect_with_alert
  end

  def destroy
    return redirect_with_alert unless valid_request?

    Current.user.prior_knowledges.find_by(course: @course, topic: @topic)&.destroy!
    redirect_to_map(notice: t("flash.prior_knowledge_unmarked"))
  end

  private
    def set_topic_context
      @course = Course.find_by(code: params[:course].to_s)
      @topic = @course&.topics&.find_by(key: params[:topic].to_s)
    end

    def valid_request? = @course.present? && @topic.present? && params[:mode].to_s != "project"

    def redirect_to_map(notice: nil, alert: nil)
      redirect_to knowledge_map_path(course: params[:course], topic: params[:topic],
                                     mode: params[:mode].presence || "course"),
                  notice:, alert:
    end

    def redirect_with_alert = redirect_to_map(alert: t("flash.prior_knowledge_invalid"))
end
