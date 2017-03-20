---
---

do ->

  results = null

  docsSearchEl = $ ".docs__search"
  item = false
  UP     = 38
  DOWN   = 40
  ENTER  = 13

  highlightRow = (search, pos) ->
    search.find(".docs__index__results__row").removeClass("hovered")
    search.find(".docs__index__results__row").eq(pos).addClass("hovered")

  keyThroughPulldown = (keynum, search) ->
    if item is false

      item = 0
      highlightRow search, item
      return

    if item isnt false 

      if keynum is DOWN or keynum is UP
        if keynum is DOWN
          item++
        else if keynum is UP
          if item is 0
            item = false
          else
            item--

        highlightRow search, item
        return

      if keynum is ENTER
        search.find(".docs__index__results__row.hovered")[0].click()
        return

  docsSearchEl.find("input").keyup (e) ->

    $thisSearch = $(this).parent()
    keynum = e.which

    if keynum in [UP, DOWN, ENTER]
      keyThroughPulldown keynum, $thisSearch
      return

    item = false

    value = $.trim($(this).val())

    if results then results.remove()
    $thisSearch.append "<div class='docs__index__results'></div>"

    results = $thisSearch.find ".docs__index__results"

    navDocs.forEach (doc) ->

      items = doc.items.filter (obj) ->
        return obj.title.toLowerCase().indexOf(value) != -1

      if items.length

        results.append "<div class='docs__index__results__header'>#{doc.title}</div>"

        items
          .map (obj) ->
            description = ""

            if obj.description
              description = "<div class='results__row__description'>#{obj.description}</div>"

            url = if obj.id then "/docs/#{obj.id}" else obj.url

            return "<a href='#{url}' class='docs__index__results__row'><span class='results__row__title'>#{obj.title}</span>#{description}</a>"
          .forEach (obj) ->
            results.append(obj)

  $(document).click (event) ->
    if !$(event.target).closest(".docs__search").length && results
      item = false
      results.remove()