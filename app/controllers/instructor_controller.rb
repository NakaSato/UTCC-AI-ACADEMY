class InstructorController < ApplicationController
  allow_only :staff

  def show
    @section = Section.for_staff(Current.user)

    # Staff with nothing to teach, and no section in the database to fall back
    # on: the screen says so rather than averaging over an empty roster.
    @report = InstructorReport.new(@section) if @section
  end
end
