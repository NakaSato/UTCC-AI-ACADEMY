---
title: Current Development Update
---

# Current Development Update

**Tags:** [#development](tags.md#development) [#backlog](tags.md#backlog) [#status](tags.md#status) [#monitoring](tags.md#monitoring) [#planning](tags.md#planning)

This is the current project status page. It is generated from the machine-readable [JSON backlog](backlog.json), which remains the single source of truth for development execution. The consolidated [product roadmap](roadmap.md) contains the UTCC Academy, AI Recruitment Platform, and Company Business Case Platform tracks, the [feature inventory](feature-inventory.md) records implemented behavior, and the [team process](process.md) defines when work is done.

{% assign current_items = site.data.backlog.items | sort: "priority" %}
{% assign blocked_items = current_items | where: "status", "blocked" %}
{% assign in_progress_items = current_items | where: "status", "in_progress" %}
{% assign verification_items = current_items | where: "status", "verification" %}
{% assign queued_items = current_items | where: "status", "queued" %}
{% comment %}
  "Current work" means work that is not finished. Rendering all of it —
  sixty-six complete items against five live ones — buried the answer to the
  only question this page is asked, and made the table forty screens long.
  Finished work is still here, one disclosure away.
{% endcomment %}
{% assign active_items = current_items | where_exp: "item", "item.status != 'complete'" %}
{% assign finished_items = current_items | where: "status", "complete" %}

<div class="status-overview my-7 grid grid-cols-2 gap-3 lg:grid-cols-3" aria-label="Current project summary">
  <div class="rounded-2xl border border-hairline bg-surface-4 p-4">
    <span>Delivery state</span>
    <strong><span class="status status-{{ site.data.backlog.delivery_state }}">{{ site.data.backlog.delivery_state | replace: "_", " " | capitalize }}</span></strong>
  </div>
  <div class="rounded-2xl border border-hairline bg-surface-4 p-4">
    <span>Current milestone</span>
    <strong><a href="{{ site.data.backlog.current_milestone.roadmap_url }}">{{ site.data.backlog.current_milestone.name | escape }}</a></strong>
  </div>
  <div class="rounded-2xl border border-hairline bg-surface-4 p-4">
    <span>In progress</span>
    <strong>{{ in_progress_items.size }}</strong>
  </div>
  <div class="rounded-2xl border border-hairline bg-surface-4 p-4">
    <span>Verification</span>
    <strong>{{ verification_items.size }}</strong>
  </div>
  <div class="rounded-2xl border border-hairline bg-surface-4 p-4">
    <span>Queued</span>
    <strong>{{ queued_items.size }}</strong>
  </div>
  <div class="rounded-2xl border border-hairline bg-surface-4 p-4">
    <span>Blocked</span>
    <strong><a href="#blockers-and-decisions">{{ blocked_items.size }}</a></strong>
  </div>
</div>

<p class="status-timestamp">
  <strong>Last updated:</strong> {{ site.data.backlog.updated_at }} ·
  <strong>Automatic refresh:</strong> {{ site.data.backlog.refresh_schedule.label }}
</p>

## Deployed revision

<div class="revision-summary rounded-2xl border border-hairline bg-surface-4 p-5">
  <dl class="grid gap-4 sm:grid-cols-2">
    <div>
      <dt>Repository</dt>
      <dd><a href="{{ site.data.build.repository_url }}">{{ site.data.build.repository | escape }}</a></dd>
    </div>
    <div>
      <dt>Commit</dt>
      <dd><a href="{{ site.data.build.commit_url }}"><code>{{ site.data.build.commit_short_sha }}</code></a> on <code>{{ site.data.build.branch | escape }}</code></dd>
    </div>
    {%- comment -%}
      The subject line, then the body behind a disclosure. This repository
      writes long commit messages on purpose, and printing one in full put
      thirty lines of prose between the reader and the work table.
    {%- endcomment -%}
    {%- assign message_lines = site.data.build.commit_message | strip | split: "
" -%}
    {%- assign subject = message_lines | first -%}
    {%- assign body = message_lines | shift | join: "
" | strip -%}
    <div class="sm:col-span-2">
      <dt>Commit message</dt>
      <dd>
        {{ subject | escape }}
        {%- if body != "" %}
          <details class="disclosure disclosure-inline">
            <summary>Full message</summary>
            <span class="commit-body">{{ body | escape | newline_to_br }}</span>
          </details>
        {%- endif %}
      </dd>
    </div>
  </dl>
</div>

## Current work

{% if active_items.size == 0 %}
<p class="empty-state">Nothing is in flight. Every item in the backlog is complete.</p>
{% else %}
<p class="section-lede">{{ active_items.size }} item{% unless active_items.size == 1 %}s{% endunless %} not finished. Owner and dependencies sit under each title; evidence opens on demand.</p>

<table class="work-table">
  <thead>
    <tr>
      <th>Item</th>
      <th>Status</th>
      <th>Evidence</th>
    </tr>
  </thead>
  <tbody>
    {% for item in active_items %}
      <tr>
        <td>
          <span class="work-title"><code>{{ item.id }}</code> {{ item.title | escape }}</span>
          <span class="work-meta">
            {{ item.owner | escape }}
            {%- if item.depends_on.size > 0 %} · needs {{ item.depends_on | join: ", " }}{% endif -%}
          </span>
        </td>
        <td><span class="status status-{{ item.status }}">{{ item.status | replace: "_", " " | capitalize }}</span></td>
        <td>{% include evidence.html evidence=item.evidence %}</td>
      </tr>
    {% endfor %}
  </tbody>
</table>
{% endif %}

<details class="disclosure">
  <summary>Completed work — {{ finished_items.size }} items</summary>

  <table class="work-table">
    <thead>
      <tr>
        <th>Item</th>
        <th>Evidence</th>
      </tr>
    </thead>
    <tbody>
      {% for item in finished_items %}
        <tr>
          <td>
            <span class="work-title"><code>{{ item.id }}</code> {{ item.title | escape }}</span>
            <span class="work-meta">{{ item.owner | escape }}</span>
          </td>
          <td>{% include evidence.html evidence=item.evidence %}</td>
        </tr>
      {% endfor %}
    </tbody>
  </table>
</details>

## Status flow

```text
Queued → In progress → Verification → Complete
                    ↘ Blocked
```

Only the states listed in `allowed_statuses` inside [backlog.json](backlog.json) may appear in current work.

## Blockers and decisions

<table>
  <thead>
    <tr>
      <th>Work item</th>
      <th>Blocker</th>
      <th>Decision owner</th>
      <th>Next action</th>
    </tr>
  </thead>
  <tbody>
    {% for item in site.data.backlog.items %}
      {% if item.blocker %}
        <tr>
          <td><code>{{ item.id }}</code></td>
          <td>{{ item.blocker.summary | escape }}</td>
          <td>{{ item.blocker.decision_owner | escape }}</td>
          <td>{{ item.blocker.next_action | escape }}</td>
        </tr>
      {% endif %}
    {% endfor %}
  </tbody>
</table>

## Verification

An item moves to **Complete** only when its evidence is recorded here and the repository's definition of done is satisfied.

- [ ] Relevant automated tests pass
- [ ] `bin/verify` passes
- [ ] Thai and English copy are updated together
- [ ] Authorization and security invariants remain enforced
- [ ] The behavior is demonstrated in the running application
- [ ] Documentation is updated in the same change

## Recently completed

<table>
  <thead>
    <tr>
      <th>ID</th>
      <th>Result</th>
      <th>Completed</th>
      <th>Evidence</th>
    </tr>
  </thead>
  <tbody>
    {% for item in site.data.backlog.recently_completed %}
      <tr>
        <td><code>{{ item.id }}</code></td>
        <td>{{ item.title | escape }}</td>
        <td>{{ item.completed_at }}</td>
        <td><a href="{{ item.evidence.url }}">{{ item.evidence.label | escape }}</a></td>
      </tr>
    {% endfor %}
  </tbody>
</table>

## Update history

Every backlog change appends an entry; existing history is never rewritten.

{%- comment -%}
  Newest first, and only the newest twelve on arrival. The history is
  append-only and already runs to two hundred entries, so showing all of it
  meant the page ended in a wall nobody scrolls to the bottom of.
{%- endcomment -%}
{% assign updates = site.data.backlog.updates | reverse %}
{% assign recent_updates = updates | slice: 0, 12 %}

<ol class="update-history">
  {% for update in recent_updates %}
    <li>
      <strong>{{ update.at }}</strong> · <code>{{ update.item_id }}</code> ·
      {{ update.from | replace: "_", " " }} → {{ update.to | replace: "_", " " }}<br>
      {{ update.summary | escape }}
      {% if update.evidence_url %}
        · <a href="{{ update.evidence_url }}">Evidence</a>
      {% endif %}
    </li>
  {% endfor %}
</ol>

{% if updates.size > 12 %}
<details class="disclosure">
  <summary>Earlier history — {{ updates.size | minus: 12 }} entries</summary>

  <ol class="update-history" start="13">
    {% for update in updates offset: 12 %}
      <li>
        <strong>{{ update.at }}</strong> · <code>{{ update.item_id }}</code> ·
        {{ update.from | replace: "_", " " }} → {{ update.to | replace: "_", " " }}<br>
        {{ update.summary | escape }}
        {% if update.evidence_url %}
          · <a href="{{ update.evidence_url }}">Evidence</a>
        {% endif %}
      </li>
    {% endfor %}
  </ol>
</details>
{% endif %}

## Agent update protocol

Every development agent must:

1. Read `docs/backlog.json` before starting work.
2. Select the highest-priority unblocked queued item.
3. Change its JSON status to `in_progress`, record its owner, and update both timestamps.
4. Append an `updates` entry for every status or material backlog change; never rewrite history.
5. Record a structured blocker as soon as progress depends on a decision or external state.
6. Move work to `verification` when implementation is finished.
7. Move work to `complete` only after adding concrete test, CI, commit, or deployment evidence.
8. Update `backlog.json` in the same change as the implementation.

Chat messages and agent summaries are notifications. The JSON backlog is the execution record, while its append-only updates and Git history preserve the audit trail.
