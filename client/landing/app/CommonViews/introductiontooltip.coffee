class IntroductionTooltip extends KDObject

  constructor: (options = {}, data) ->

    super options, data

    @setData @getIntroData() unless @getData() # we just know the intro view and should find the data, called from viewAppended
    return unless @getData() # we know introId but we have no JIntroSnippet for this view, should return

    {@introId} = @getData() # we have an intro view and data for this view, go on!
    @storage   = @getSingleton("mainController").introductionTooltipStatusStorage # to store tooltip status
    return if @shouldNotDisplay() # user has already closed this introduction before, so don't show it again

    parentView = @getOptions().parentView or @getParentView() # we came from db query and don't know the view, should find
    return unless parentView # view not appended to dom yet, probably came from db query

    view       = null
    try view   = eval @getData().snippet?.split("&quot;").join("\"") # trying to eval snippet, sanity check
    return unless view instanceof KDView # we will add this as a subview, should be a KDView instance

    view.addSubView @closeButton = new KDCustomHTMLView
      tagName  : "span"
      cssClass : "close-icon"
      click    : => @close()

    parentView.setTooltip { view }
    parentView.tooltip.show()

  close: ->
    @storage.setValue @introId, yes

  shouldNotDisplay: ->
    return @storage.getValue(@introId) is yes

  getIntroData: ->
    {introSnippets} = @getSingleton "mainController"
    ourSnippet = null
    for key, snippet of introSnippets
      if @getOptions().parentView.getOptions().introId is snippet.introId
        ourSnippet = snippet
    return ourSnippet

  getParentView: ->
    view      = null
    {introId} = @getData()
    instances = KD.introInstances

    for key, instance of instances
      if instance.getOptions().introId is introId
        view = instance

    return view