---
---

do ->

  results = null

  docsSearchEl = $ ".docs__search"
  item   = 0
  UP     = 38
  DOWN   = 40
  ENTER  = 13

  highlightRow = (search, pos) ->
    search.find(".docs__index__results__row").removeClass("hovered")
    search.find(".docs__index__results__row").eq(pos).addClass("hovered")

  keyThroughPulldown = (keynum, search) ->

    switch keynum
      when DOWN
        item++
        highlightRow search, item

      when UP
        if item isnt 0
          item--
          highlightRow search, item

      when ENTER
        search.find(".docs__index__results__row.hovered")[0].click()

  createResultsRowsHeader = (item) ->
    "<div class='docs__index__results__header'>#{item.title}</div>"

  createResultsRows = (items) ->
    items.map(createResultsRowTemplate).join("")

  createResultsRowTemplate = (obj) ->

    description = if obj.description then "<span class='results__row__description'>#{obj.description}</span>" else ""
    url         = if obj.id then "/docs/#{obj.id}" else obj.url

    "<a href='#{url}' class='docs__index__results__row'>
      <span class='results__row__title'>#{obj.title}</span>
      #{description}
    </a>"


  docsSearchEl.find("input").keyup (e) ->

    $thisSearch = $(this).parent()
    keynum = e.which

    if keynum in [UP, DOWN, ENTER]
      keyThroughPulldown keynum, $thisSearch
      return

    item = false
    if results then results.remove()

    value = $.trim($(this).val())
    $thisSearch.append "<div class='docs__index__results'></div>"
    results = $thisSearch.find ".docs__index__results"

    navDocs.forEach (doc) ->

      items = doc.items.filter (obj) ->
        return obj.title.toLowerCase().indexOf(value) != -1

      if items.length
        results.append createResultsRowsHeader doc
        results.append createResultsRows items

        results.find(".docs__index__results__row").first().addClass("hovered")

  $(document).click (event) ->
    if !$(event.target).closest(".docs__search").length && results
      item = false
      results.remove()