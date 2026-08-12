# The student hands work over; the company that hosted the internship reads it
# while the internship is open.
#
# Downloads go through here rather than through an Active Storage blob URL. A
# signed blob URL authorizes the *link*, not the reader, and it keeps working
# after a placement ends and after a membership is revoked — which is exactly
# what decision 5's access rule says must stop. This action re-derives the
# answer on every request.
class InternshipDeliverablesController < ApplicationController
  def create
    placement = InternshipPlacement.find(params[:id])
    deliverable = placement.deliverables.new(deliverable_params.merge(author: Current.user))
    deliverable.save!

    redirect_to internship_placement_path(placement), notice: t("flash.internship_deliverable_added")
  rescue ActiveRecord::RecordInvalid => error
    redirect_to internship_placement_path(placement),
                alert: error.record.errors.full_messages.to_sentence.presence ||
                       t("flash.internship_deliverable_unavailable")
  end

  def destroy
    placement = InternshipPlacement.find(params[:id])
    placement.deliverables.find(params[:deliverable_id]).destroy_for!(actor: Current.user)

    redirect_to internship_placement_path(placement), notice: t("flash.internship_deliverable_removed")
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotFound
    redirect_to internship_placement_path(placement), alert: t("flash.internship_deliverable_unavailable")
  end

  # Always an attachment, never inline: the file is somebody else's upload and
  # this application scans nothing, so a reader's browser is never asked to
  # interpret it. Rails' default headers add `nosniff`, which is what stops the
  # declared type from being second-guessed.
  def download
    placement = InternshipPlacement.find(params[:id])
    deliverable = placement.deliverables.find(params[:deliverable_id])
    raise ActiveRecord::RecordNotFound unless deliverable.readable_by?(Current.user)

    send_data deliverable.file.download, filename: deliverable.file.filename.to_s,
              type: deliverable.file.content_type, disposition: "attachment"
  end

  private
    def deliverable_params = params.expect(internship_deliverable: [ :title, :file ])
end
