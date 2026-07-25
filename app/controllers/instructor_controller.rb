class InstructorController < ApplicationController
  allow_only :staff

  def show
    @stats = InstructorReport.stats
    @hard_topics = InstructorReport.hard_topics
    @roster = InstructorReport.roster
  end
end
