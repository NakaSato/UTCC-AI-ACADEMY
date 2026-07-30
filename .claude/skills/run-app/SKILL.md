---
name: run-app
description: Launch the app and drive it in a real browser — sign in, navigate, screenshot a screen
---

## Run the app and look at it

**Tags:** [#skills](../../../docs/tags.md#skills) [#development](../../../docs/tags.md#development) [#verification](../../../docs/tags.md#verification)

The proven path on this machine, cold-started and verified. Use it whenever a
change needs to be *seen* working rather than only tested.

### 1. Server

`bin/dev` runs Puma **and** the Tailwind watcher — CSS changes need it. Check
whether one is already up before starting another:

```bash
lsof -ti:3000 || bin/dev   # something answering on :3000 is usually it
curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/   # expect 200
```

If the catalog looks empty, the database has no taxonomy: `bin/rails db:seed`
(idempotent, restores courses/topics/section/demo accounts).

### 2. Browser

**There is no Chrome, chromedriver, or browser CLI on this machine.** Microsoft
Edge is installed, and the `selenium-webdriver` gem (already in the Gemfile)
drives it headless — selenium's manager fetches `msedgedriver` itself on first
run, nothing to install. The registered test driver in
`test/application_system_test_case.rb` is the reference configuration.

Ad-hoc driving, run with `bundle exec ruby`:

```ruby
require "selenium-webdriver"

opts = Selenium::WebDriver::Options.edge
opts.add_argument("--headless=new")
opts.add_argument("--window-size=1440,1200")
opts.add_argument("--hide-scrollbars")
# The app negotiates locale from the browser; a headless profile asks for
# English. Pin Thai to see the default copy:
opts.add_argument("--lang=th")
opts.add_preference("intl.accept_languages", "th")

driver = Selenium::WebDriver.for(:edge, options: opts)
wait = Selenium::WebDriver::Wait.new(timeout: 15)

# Sign in through the real form (field names: student_id, password;
# the submit is input[type=submit] — click_button is ambiguous with the tab).
driver.navigate.to "http://localhost:3000/login"
driver.find_element(name: "student_id").send_keys("2011071730001")
driver.find_element(name: "password").send_keys("utcc2026")
driver.find_element(css: "input[type=submit]").click
wait.until { driver.current_url !~ %r{/login} }

driver.navigate.to "http://localhost:3000/progress"
wait.until { driver.find_elements(css: "main").any? }
sleep 2   # cards animate in with staggered delays; capturing early reads blank

height = driver.execute_script("return document.documentElement.scrollHeight")
driver.manage.window.resize_to(1440, height + 120)
driver.save_screenshot("shot.png")
driver.quit
```

### 3. Accounts (seeded, password `utcc2026` for all)

| ID | Role | Lands on |
| --- | --- | --- |
| `2011071730001` | student, some progress | catalog |
| `2011071730002` | student, further along | catalog |
| `2011071730801` | instructor (teaches BA-2) | catalog, has `/instructor` |
| `2011071730802` | admin | redirected to `/admin` |

### Gotchas already paid for

- **Screenshot before the entrance animations finish → blank page.** Sleep ~2s
  after load, or the cards are at opacity 0.
- An admin cannot see the learner screens — `/` bounces them to `/admin`.
- A brand-new student can only open module 1 topics; deeper lesson URLs
  redirect back with a "locked" flash. Use `topic=1-1`.
- Write screenshots to the session scratchpad, not the repo.
