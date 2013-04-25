class CounterGroupView extends KDCustomHTMLView
  constructor:(options = {},data)->
    options.tagName = "div"
    super options,data

  viewAppended:->
    counters = @getData()
    for title, options of counters
      @setPartial @getCounterHTML title, options.count

    # setInterval =>
    #   partial = ""
    #   for title, options of counters
    #     partial += @getCounterHTML title, options.count++
    #   @updatePartial partial
    # ,1

  getNumbersHTML:(count)->
    str   = count + ""
    group = ""
    for digit in str
      group += "<span>#{digit}</span>"

    return group

  getCounterHTML:(title,count)->
    """
    <div class="acounter">
      <div class="numholder">
        #{@getNumbersHTML count}
      </div>
      #{title}
    </div>
    """
