class InstructorController < ApplicationController
  allow_only :staff

  def show
    @section = Section.for_staff(Current.user)

    # Staff with nothing to teach, and no section in the database to fall back
    # on: the screen says so rather than averaging over an empty roster.
    @report = InstructorReport.new(@section) if @section
  end

  # The export the screen's button points at. Same gate as the screen; staff
  # with no section have nothing to download and go back to the notice that
  # says so.
  def grades
    section = Section.for_staff(Current.user)
    return redirect_to instructor_path if section.nil?

    report = InstructorReport.new(section)
    send_data report.grades_csv, filename: report.grades_filename,
                                 type: "text/csv; charset=utf-8", disposition: "attachment"
  end
end
