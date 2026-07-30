---
title: Development Status
---

# Development Status

**Tags:** [#development](tags.md#development) [#backlog](tags.md#backlog) [#status](tags.md#status) [#monitoring](tags.md#monitoring) [#planning](tags.md#planning)

The machine-readable [JSON backlog](backlog.json) is the single source of truth for current development execution. This HTML page is generated from it. The [product roadmap](roadmap.md) controls priority, the [feature inventory](feature-inventory.md) records implemented behavior, and the [team process](process.md) defines when work is done.

- **Status updated:** {{ site.data.backlog.updated_at }}
- **Delivery state:** {{ site.data.backlog.delivery_state | capitalize }}
- **Current milestone:** [{{ site.data.backlog.current_milestone.name }}]({{ site.data.backlog.current_milestone.roadmap_url }})
- **Scheduled refresh:** {{ site.data.backlog.refresh_schedule.label }}

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
    {% for item in site.data.backlog.items %}
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
- [ ] `bin/ci` passes
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
