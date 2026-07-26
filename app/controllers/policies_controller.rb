class PoliciesController < ApplicationController
  # Readable without an account: the footer links here from the landing page, and
  # sign-up asks a visitor to accept both before they have one.
  allow_unauthenticated_access

  def privacy = show(:privacy)

  def terms = show(:terms)

  private
    # Both documents are the same shape, so they share one template.
    def show(document)
      @document = document
      @sections = Policy.sections_for(document)

      render :show
    end
end
