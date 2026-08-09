class ContributorsController < ApplicationController
  # This is a public presentation page. It contains role-based, editorial
  # profiles rather than student records, so it does not cross the private
  # candidate-profile boundary in the recruitment specification.
  allow_unauthenticated_access only: :index

  def index
    @contributors = %i[curriculum community design platform].map do |key|
      { key:, index: format("%02d", %i[curriculum community design platform].index(key) + 1) }
    end
  end
end
