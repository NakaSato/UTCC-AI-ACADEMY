// Posting a lesson answer for grading. The exercise and the coding task both
// send what the student did and render the verdict that comes back — neither
// knows the answer key, which is the point.
//
// Not in app/javascript/controllers: pin_all_from registers everything in that
// directory as a Stimulus controller, and this is a plain function.
export async function grade({ url, course, topic, kind, answer }) {
  const token = document.querySelector("meta[name=csrf-token]")?.content

  try {
    const response = await fetch(url, {
      method: "POST",
      headers: { "Content-Type": "application/json", "X-CSRF-Token": token },
      body: JSON.stringify({ kind, course, topic, answer })
    })

    // A refusal is not a fail — the topic is locked, or the session went away.
    // The caller re-enables its control rather than telling the student they
    // got it wrong.
    if (!response.ok) return null

    return await response.json()
  } catch {
    // Offline, or the request was blocked.
    return null
  }
}
