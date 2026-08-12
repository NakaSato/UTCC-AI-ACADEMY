import characterCounter from "islands/character_counter"

// What `vue-island` may mount, by name. A data attribute names an entry here
// and nothing else, so a template cannot reach arbitrary code.
export default {
  "character-counter": characterCounter
}
