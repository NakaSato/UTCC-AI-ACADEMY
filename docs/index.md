---
title: Current Development Update
---

# Current Development Update

**Tags:** [#development](tags.md#development) [#backlog](tags.md#backlog) [#status](tags.md#status) [#monitoring](tags.md#monitoring) [#planning](tags.md#planning)

This is the current project status page. It is generated from the machine-readable [JSON backlog](backlog.json), which remains the single source of truth for development execution. The [UTCC Academy product roadmap](roadmap.md) controls current priority, the [AI Recruitment Platform roadmap](roadmap-ai-recruitment-platform.md) is a separate draft initiative, the [feature inventory](feature-inventory.md) records implemented behavior, and the [team process](process.md) defines when work is done.

{% assign current_items = site.data.backlog.items | sort: "priority" %}
{% assign blocked_items = current_items | where: "status", "blocked" %}
{% assign in_progress_items = current_items | where: "status", "in_progress" %}
{% assign verification_items = current_items | where: "status", "verification" %}
{% assign queued_items = current_items | where: "status", "queued" %}

<div class="status-overview my-7 grid grid-cols-2 gap-3 lg:grid-cols-3" aria-label="Current project summary">
  <div class="rounded-xl border border-stone-200 bg-stone-100 p-4">
    <span>Delivery state</span>
    <strong><span class="status status-{{ site.data.backlog.delivery_state }}">{{ site.data.backlog.delivery_state | replace: "_", " " | capitalize }}</span></strong>
  </div>
  <div class="rounded-xl border border-stone-200 bg-stone-100 p-4">
    <span>Current milestone</span>
    <strong><a href="{{ site.data.backlog.current_milestone.roadmap_url }}">{{ site.data.backlog.current_milestone.name | escape }}</a></strong>
  </div>
  <div class="rounded-xl border border-stone-200 bg-stone-100 p-4">
    <span>In progress</span>
    <strong>{{ in_progress_items.size }}</strong>
  </div>
  <div class="rounded-xl border border-stone-200 bg-stone-100 p-4">
    <span>Verification</span>
    <strong>{{ verification_items.size }}</strong>
  </div>
  <div class="rounded-xl border border-stone-200 bg-stone-100 p-4">
    <span>Queued</span>
    <strong>{{ queued_items.size }}</strong>
  </div>
  <div class="rounded-xl border border-stone-200 bg-stone-100 p-4">
    <span>Blocked</span>
    <strong><a href="#blockers-and-decisions">{{ blocked_items.size }}</a></strong>
  </div>
</div>

<p class="status-timestamp">
  <strong>Last updated:</strong> {{ site.data.backlog.updated_at }} ·
  <strong>Automatic refresh:</strong> {{ site.data.backlog.refresh_schedule.label }}
</p>

## Deployed revision

<div class="revision-summary rounded-xl border border-stone-200 bg-white p-5 shadow-sm">
  <dl class="grid gap-4 sm:grid-cols-2">
    <div>
      <dt>Repository</dt>
      <dd><a href="{{ site.data.build.repository_url }}">{{ site.data.build.repository | escape }}</a></dd>
    </div>
    <div>
      <dt>Commit</dt>
      <dd><a href="{{ site.data.build.commit_url }}"><code>{{ site.data.build.commit_short_sha }}</code></a> on <code>{{ site.data.build.branch | escape }}</code></dd>
    </div>
    <div class="sm:col-span-2">
      <dt>Commit message</dt>
      <dd>{{ site.data.build.commit_message | escape | newline_to_br }}</dd>
    </div>
  </dl>
</div>

## Current work

<table>
  <thead>
    <tr>
      <th>ID</th>
      <th>Work item</th>
      <th>Status</th>
      <th>Owner</th>
      <th>Dependency</th>
      <th>Evidence</th>
    </tr>
  </thead>
  <tbody>
    {% for item in current_items %}
      <tr>
        <td><code>{{ item.id }}</code></td>
        <td>{{ item.title | escape }}</td>
        <td><span class="status status-{{ item.status }}">{{ item.status | replace: "_", " " | capitalize }}</span></td>
        <td>{{ item.owner | escape }}</td>
        <td>
          {% if item.depends_on.size > 0 %}
            {{ item.depends_on | join: ", " }}
          {% else %}
            None
          {% endif %}
        </td>
        <td>
          {% for evidence in item.evidence %}
            <a href="{{ evidence.url }}">{{ evidence.label | escape }}</a>{% unless forloop.last %}<br>{% endunless %}
          {% endfor %}
        </td>
      </tr>
    {% endfor %}
  </tbody>
</table>

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

<ol class="update-history">
  {% assign updates = site.data.backlog.updates | reverse %}
  {% for update in updates %}
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
