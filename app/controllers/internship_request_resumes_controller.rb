# The résumé a student chose to share with one company, served from the copy
# that already exists on their candidate profile.
#
# Sharing is a decision the student makes and unmakes; reading it is re-derived
# per request from the state of the request and the placement it produced, so a
# rejected request and an ended internship both close the door. See ADR-0041
# decision 5 and `InternshipRequest#resume_readable_by?`.
class InternshipRequestResumesController < ApplicationController
  def create
    internship_request = own_request
    internship_request.share_resume!(actor: Current.user)

    redirect_to internship_request_path(internship_request), notice: t("flash.internship_resume_shared")
  rescue ActiveRecord::RecordInvalid
    redirect_to internship_request_path(internship_request), alert: t("flash.internship_resume_unavailable")
  end

  def destroy
    internship_request = own_request
    internship_request.unshare_resume!(actor: Current.user)

    redirect_to internship_request_path(internship_request), notice: t("flash.internship_resume_unshared")
  rescue ActiveRecord::RecordInvalid
    redirect_to internship_request_path(internship_request), alert: t("flash.internship_resume_unavailable")
  end

  # An attachment, never inline — the same rule a deliverable download follows,
  # and for the same reason.
  def show
    internship_request = InternshipRequest.find(params[:id])
    raise ActiveRecord::RecordNotFound unless internship_request.resume_readable_by?(Current.user)

    resume = internship_request.shareable_resume
    send_data resume.download, filename: resume.filename.to_s, type: resume.content_type,
              disposition: "attachment"
  end

  private
    def own_request = Current.user.internship_requests.find(params[:id])
end
