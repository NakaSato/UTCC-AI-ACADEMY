// Search and pagination for the status page.
//
// The first JavaScript on this site, so it is written to be optional. Every
// control it drives ships in the HTML with `hidden` on it and is revealed
// here; with JavaScript off the page is exactly what it was — every row
// rendered, nothing to click, nothing broken. A status page that goes blank
// when a script fails is worse than a long one.
//
// Search and pagination are one pass, not two features. Filtering decides
// which rows are eligible and paging decides which eligible rows are on
// screen, so both run through `render()` — otherwise a search would page
// through rows it had just hidden.
(function () {
  "use strict";

  var PAGE_SIZE = 20;

  function text(element) {
    return (element.textContent || "").toLowerCase().replace(/\s+/g, " ").trim();
  }

  // A list that can be searched, paged, or both. `rows` never changes; what
  // changes is which of them match and which page is showing.
  function List(container) {
    this.container = container;
    this.rows = Array.prototype.slice.call(container.children);
    this.haystacks = this.rows.map(text);
    this.paged = container.hasAttribute("data-paginate");
    // The box is labelled "Search work" and sits in the work section, so it
    // filters work. Letting it reach the update history as well made a search
    // for "blocked" report 59 matches against three blocked items, because
    // every status transition through blocked is in that history.
    this.searchable = container.hasAttribute("data-search");
    this.page = 0;
    this.query = "";
    this.controls = null;
    // An <ol> numbers its items, so a page has to say where it starts.
    this.ordered = container.tagName === "OL";
    this.start = parseInt(container.getAttribute("start"), 10) || 1;
  }

  List.prototype.matching = function () {
    if (this.query === "" || !this.searchable) return this.rows;

    var terms = this.query.split(" ");
    var haystacks = this.haystacks;

    return this.rows.filter(function (row, index) {
      return terms.every(function (term) {
        return haystacks[index].indexOf(term) !== -1;
      });
    });
  };

  List.prototype.render = function () {
    var matches = this.matching();
    // Searching shows every match rather than the first page of them: a
    // result you have to page to is a result you will not find.
    var paging = this.paged && this.query === "";
    var pages = paging ? Math.max(1, Math.ceil(matches.length / PAGE_SIZE)) : 1;

    if (this.page > pages - 1) this.page = pages - 1;

    var from = paging ? this.page * PAGE_SIZE : 0;
    var to = paging ? from + PAGE_SIZE : matches.length;
    var visible = matches.slice(from, to);

    this.rows.forEach(function (row) {
      row.hidden = visible.indexOf(row) === -1;
    });

    if (this.ordered) this.container.setAttribute("start", this.start + from);
    if (this.controls) this.controls.update(this.page, pages, matches.length, paging);

    return matches.length;
  };

  // Prev/next with a position readout. Built here rather than in the markup
  // because without this script there are no pages to move between.
  List.prototype.buildControls = function () {
    if (!this.paged) return;

    var list = this;
    var nav = document.createElement("nav");
    nav.className = "pagination";
    nav.setAttribute("aria-label", "Pages");

    var previous = document.createElement("button");
    previous.type = "button";
    previous.textContent = "Previous";

    var next = document.createElement("button");
    next.type = "button";
    next.textContent = "Next";

    var status = document.createElement("p");
    status.setAttribute("role", "status");
    status.setAttribute("aria-live", "polite");

    previous.addEventListener("click", function () {
      list.page = Math.max(0, list.page - 1);
      list.render();
      list.container.scrollIntoView({ block: "nearest" });
    });

    next.addEventListener("click", function () {
      list.page = list.page + 1;
      list.render();
      list.container.scrollIntoView({ block: "nearest" });
    });

    nav.appendChild(previous);
    nav.appendChild(status);
    nav.appendChild(next);

    var anchor = this.container.closest("table") || this.container;
    anchor.parentNode.insertBefore(nav, anchor.nextSibling);

    this.controls = {
      update: function (page, pages, total, paging) {
        nav.hidden = !paging || total <= PAGE_SIZE;
        previous.disabled = page === 0;
        next.disabled = page >= pages - 1;
        status.textContent = "Page " + (page + 1) + " of " + pages + " · " + total + " items";
      }
    };
  };

  function ready() {
    var lists = Array.prototype.map.call(
      document.querySelectorAll("[data-list]"),
      function (container) {
        var list = new List(container);
        list.buildControls();
        list.render();
        return list;
      }
    );

    if (lists.length === 0) return;

    var search = document.querySelector("[data-status-search]");
    if (!search) return;

    var input = search.querySelector("input");
    var readout = search.querySelector("[data-search-count]");
    // Disclosures the search opened, so clearing the box puts them back as
    // they were rather than leaving sixty-six finished items on screen.
    var opened = [];

    search.hidden = false;

    function apply() {
      var query = input.value.toLowerCase().replace(/\s+/g, " ").trim();
      var total = 0;

      lists.forEach(function (list) {
        list.query = query;
        list.page = 0;
        var matches = list.render();
        if (list.searchable) total += matches;

        // Only a list the search actually filters is worth opening. The
        // history is not searched, so every one of its entries "matches",
        // and opening it on any query would drop 186 rows onto the page.
        if (!list.searchable) return;

        var disclosure = list.container.closest("details");
        if (!disclosure) return;

        if (query !== "" && matches > 0 && !disclosure.open) {
          disclosure.open = true;
          opened.push(disclosure);
        }
      });

      if (query === "") {
        opened.forEach(function (disclosure) { disclosure.open = false; });
        opened = [];
        readout.textContent = "";
        return;
      }

      readout.textContent = total === 0
        ? "No items match “" + input.value.trim() + "”."
        : total + (total === 1 ? " item matches" : " items match") + " “" + input.value.trim() + "”.";
    }

    input.addEventListener("input", apply);
    input.addEventListener("search", apply);
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", ready);
  } else {
    ready();
  }
})();
