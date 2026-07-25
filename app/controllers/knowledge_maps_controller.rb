class KnowledgeMapsController < ApplicationController
  def show
    @mode = params[:mode] == "project" ? "project" : "course"
    @selected = KnowledgeMap.find(params[:topic]) || KnowledgeMap.find(KnowledgeMap::DEFAULT_SELECTED)
    @trail = KnowledgeMap.path_to(@selected.id)

    # A group expands when it is on the path to the selection, so navigating the
    # tree never needs client state — the URL carries everything.
    @open = KnowledgeMap::DEFAULT_OPEN | @trail.map(&:id)
    @rows = KnowledgeMap.rows(open: @open)
    @cards = @selected.children
    @legend_open = params[:legend] == "1"
  end
end
