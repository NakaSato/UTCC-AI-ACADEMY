class ProposalRequestsController < ApplicationController
  allow_only :student, :instructor

  def new
    @proposal = Current.user.proposal_requests.new(category: "feature")
  end

  def create
    @proposal = Current.user.proposal_requests.new(proposal_params)
    @proposal.save!

    redirect_to proposal_request_path(@proposal), notice: t("flash.proposal_request_created")
  rescue ActiveRecord::RecordInvalid
    render :new, status: :unprocessable_entity
  end

  def show
    @proposal = Current.user.proposal_requests.find(params[:id])
    # The last decision is the current answer; the ones before it are the
    # console's history and not the author's business — SPEC-0050.
    @decision = @proposal.latest_decision
  end

  private
    # This is an explicit contribution entry point. Send signed-out visitors
    # straight to the credential screen while keeping the deep-link return URL.
    def request_authentication
      session[:return_to_after_authenticating] = request.url
      redirect_to login_path, alert: t("flash.sign_in_required")
    end

    def proposal_params
      params.expect(proposal_request: [ :title, :category, :problem, :idea, :impact ])
    end
end
