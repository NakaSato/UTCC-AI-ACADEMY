# The three files a crawler or a model reads before it reads a page: what it may
# fetch, what exists, and a plain-language summary of the site.
#
# They are rendered by Rails rather than checked into `public/` because all three
# have to name absolute URLs and this app has no configured host — `config/deploy.yml`
# is still a placeholder, so the only thing that knows where the site lives is the
# request. `public/robots.txt` is gone for the same reason: a static file would be
# served first and this action would never run.
class CrawlersController < ApplicationController
  allow_unauthenticated_access

  # Three pages are readable without an account; everything else is behind
  # `require_authentication` and answers a redirect to `/`. Saying so costs one
  # line and saves a crawler from discovering it one 302 at a time.
  DISALLOWED = %w[
    /login /register /forgot-password /reset-password
    /courses /lesson /my-learning /map /progress /leaderboard /instructor /admin
  ].freeze

  # The model crawlers, named. They are given exactly the rules everyone else
  # gets — the point of listing them is that a group written by name is *replaced*
  # by, not added to, the wildcard group, so a future `Disallow` in one of them
  # cannot quietly apply to the other.
  AI_AGENTS = %w[
    ClaudeBot Claude-User Claude-SearchBot anthropic-ai
    GPTBot ChatGPT-User OAI-SearchBot
    Google-Extended PerplexityBot Perplexity-User
    Applebot-Extended meta-externalagent CCBot
  ].freeze

  def robots
    @disallowed = DISALLOWED
    @agents = AI_AGENTS
    @sitemap_url = sitemap_url
  end

  # Paths rather than URLs: each one is listed once per language, and the view is
  # what knows how a language becomes a URL.
  def sitemap
    @paths = [ root_path, privacy_path, terms_path ]
  end

  # One file for a site with two languages. It is written in English — the
  # language the models reading it index best — and says so; the pages it points
  # at are served in Thai by default.
  def llms = I18n.with_locale(:en) { render :llms }
end
