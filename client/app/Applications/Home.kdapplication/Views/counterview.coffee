class CounterGroupView extends KDCustomHTMLView

  constructor:(options = {},data)->
    options.tagName  = "div"
    options.cssClass = "counters"
    super options, data
    @counters = {}
    counters = @getData()
    for title, options of counters
      @counters[title] = new CounterView {title}, options
    @$().html "" # tmp: clear the lazy dom stuff
    @addSubView counter for title, counter of @counters

class CounterView extends KDCustomHTMLView

  constructor:(options = {}, data)->

    options.title        or= ''
    options.digitOptions or= {}
    options.minDigits     ?= 6
    options.cssClass     or= "counter"
    options.tagName        = "figure"

    super options, data

  viewAppended:->

    @addSubView @title = new KDCustomHTMLView
      tagName  : 'h6'
      cssClass : 'title'
      partial  : @getOption('title')+':'

    @addSubView @digitWrapper = new KDCustomHTMLView
      tagName  : 'div'

    @createDigits()
    @emit "ready"

    # to update the counter just call update with the new count
    # uncomment this test case below for a demo
    # @utils.repeat 50, =>
    #   @update @getData().count + @utils.getRandomNumber(10)

  createDigits:->
    {count} = @getData()
    {digitOptions, minDigits} = @getOptions()
    @prevCount = count + ''

    # create leading zeros
    # if minDigits option is passed
    if @prevCount.length < minDigits
      for i in [@prevCount.length...minDigits]
        @prevCount = '0' + @prevCount
    # create digit subViews if they are not created alread
    # and add the subView
    for value, i in @prevCount when not @["digit#{i}"]
      @["digit#{i}"] = new CounterDigitView digitOptions, {value}
      @digitWrapper.addSubView @["digit#{i}"]

  increment:(val=0)->
    {count} = @getData()
    @update count + val

  decrement:(val=0)->
    {count} = @getData()
    @update count - val

  update:(count)->
    @getData().count = count
    @createDigits()
    {count}     = @getData()
    newCountStr = count+''
    for value, i in newCountStr
      # digitDiff is to determine which subview is for which digitView after
      # we update the count. In case of minDigits option is set
      # or the newCount has more digits than it had previously.
      digitDiff = if newCountStr.length >= @prevCount.length
      then newCountStr.length - @prevCount.length
      else @prevCount.length - newCountStr.length

      @["digit#{i+digitDiff}"].update value

class CounterDigitView extends KDCustomHTMLView

  constructor:(options = {}, data = {})->

    options.base    ?= 10
    options.tagName or= 'i'
    data.value      ?= 0

    super options, data

  update:(newValue)->
    {value} = @getData()
    return if value is newValue
    @getData().value = newValue
    @updatePartial @partial @getData().value

  viewAppended:-> @updatePartial @partial @getData().value

  partial:(value)->
    """<span/>#{value}"""
