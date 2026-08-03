class KnowledgeMapsController < ApplicationController
  def show
    @course = CourseCatalog.find(params[:course].presence || Syllabus::DEFAULT_COURSE, user: Current.user) ||
              CourseCatalog.find(Syllabus::DEFAULT_COURSE, user: Current.user)
    @mode = params[:mode] == "project" ? "project" : KnowledgeMap::DEFAULT_MODE
    @roots = KnowledgeMap.curriculum(@course.code, user: Current.user, mode: @mode)
    default_selected = @roots.flat_map { |root| root.children }.flat_map(&:children).find(&:leaf?) || @roots.first
    @selected = KnowledgeMap.find(params[:topic], nodes: @roots) || default_selected
    @trail = KnowledgeMap.path_to(@selected.id, nodes: @roots)

    # A group expands when it is on the path to the selection, so navigating the
    # tree never needs client state — the URL carries everything.
    @open = @roots.flat_map { |root| [ root.id, *root.children.map(&:id) ] } | @trail.map(&:id)
    @rows = KnowledgeMap.rows(open: @open, nodes: @roots)
    @cards = @selected.children
    @legend_open = params[:legend] == "1"
  end
end
