# The landing page CMS

`/` for a signed-out visitor is the one screen an admin can change without a deploy, and **the only content in the app that is fully a CMS** — not just reworded but added to, reordered and deleted from, at `/admin?tab=landing`.

`CLAUDE.md` keeps the two invariants this file explains (9 and 10) and the rule that `Landing` is a read model rather than a placeholder module. Everything else about how the copy resolves lives here. **Read it before touching `Landing`, `LandingCard`, `LandingText` or `AdminController#update_landing`** — the ladder in §2 is subtle and silently degrades rather than failing.

It used to be the exception to every rule in this project: two dozen lines of hardcoded Thai in `app/views/home/index.html.erb` and five arrays of it in a private `HomeController#landing`.

## 1. Two halves, in two places

`Landing` holds no taxonomy of its own. The five card collections that were `TOPICS`/`TRACKS`/`SHARES`/`EVENTS`/`FAQS` are `landing_cards` rows; `TRACK_FILTERS` is the one constant left, because it is the three shared `levels.*` and not a collection.

| | Home | Editable how |
| --- | --- | --- |
| Which cards exist, in what order, a track's level and weeks, an event's date | `landing_cards` | add / reorder / delete, and the attributes ride on the copy form |
| Every word a card shows | `landing.*` in both locale files, with `landing_texts` in front | the bilingual editor |

**Its joins are by key, not by position.** A card looks up its own copy by its own slug (`LandingCard#prefix` — `tracks` and `events` nest under `items.` in the locale files, which is the one thing that map exists for), so adding a card never shifts the copy of the card below it. That is the opposite of the positional joins everywhere else in the app, and it is what makes the collection editable at all.

## 2. The three-step ladder

**The locale files are the default, not the last word — and for a card an admin created there is no default at all.** `Landing.copy(key)` reconciles those two cases:

```ruby
LandingText.for(key) || default(key).presence || LandingText.any(key).to_s
```

Every reader on every `Data` object goes through it, and so does the view — which is why the section headings in `home/index.html.erb` are `Landing.copy("tracks.title")` rather than `t()`. The steps matter in this order:

1. **What an admin wrote in this language.**
2. **What ships in this language.** `Landing.default` is `I18n.t(…, default: nil)`, and the explicit `nil` is load-bearing: without it a card an admin added renders `translation missing`. Because this beats step 3, a Thai-only rewrite never displaces the English the repo ships.
3. **What an admin wrote in the other language.** This keeps an admin-made card visible on both pages rather than blank in one, and keeps a blank `name` out of the `Course`/`Event` JSON-LD.

## 3. The rules that follow

- **A row is a departure from the default, never a copy of it.** `LandingText.write` deletes rather than stores when a box is cleared or retyped to match what ships, so the editor needs no reset control and the locale files can never be shadowed by a stale duplicate of themselves. **That is invariant 9.** For an admin-made card the default is nothing, so clearing simply removes the copy.
- **Deleting a card deletes its copy** — `LandingCard`'s `after_destroy`. **That is invariant 10**; without it a slug that came back would silently inherit someone else's words.
- **The editable surface is derived, not listed.** `Landing.groups` is built from the rows, so a card an admin adds arrives in the editor with copy fields of its own. `editable_keys` is the whitelist `LandingText` validates against and `AdminController#update_landing` reads params through. **Chrome is deliberately outside it** — `landing.brand_*`, `landing.nav.*` and `hero.logo_alt` belong to `shared/_header`, and `levels.*`/`units.*` are shared with the catalog, so the landing editor cannot reword another screen.
- **A track's level and an event's date are on the card, not in the copy.** They are one fact in both languages, so they are columns; they are edited on the same form as the copy because they are the same card. An event's `starts_on` is a real `date`, so an unparseable one casts to "undated" rather than shipping an invalid `startDate`.
- **A slug is generated, never typed** (`LandingCard.key_for`) — an admin should not have to invent a stable identifier. `parameterize` strips non-ASCII, so a Thai-only title falls back to `"card"` plus a numeric suffix.
- **Both tables are read once per request and memoised on `Current`**, for the same reason `Current.syllabus` exists. `LandingText.overrides` and `Landing.cards`; anything that writes must call `LandingText.forget` / `Landing.forget_cards`.
- **The taxonomy is three copies that must agree** — the `CreateLandingCards` migration, `db/seeds.rb` above the `Rails.env.local?` fence, and `test/fixtures/landing_cards.yml`. `landing_card_test.rb` asserts the shape all three have to produce, exactly as `taxonomy_test.rb` does for the catalog.

## 4. What the tests cover

`landing_card_test.rb`, `landing_text_test.rb` and `admin_landing_test.rb`: the three copies of the taxonomy agreeing, slugs generated rather than typed, a card moving and a card's deletion taking its copy with it; then that a copy row is only ever a departure from what ships, that a key the page does not render cannot be written, that a card written in one language shows that language in the other, and that adding, reordering and deleting all reach the page a stranger reads.

`landing_test.rb`, `structured_data_test.rb` and `crawlers_test.rb` all assert against the locale files, which works only because `test/fixtures/landing_texts.yml` is empty — an empty table *is* the app as shipped.
