class IntroductionTooltipController extends KDController

  constructor: (options = {}, data) ->

    super options, data

    @currentTimestamp  = Date.now()
    @shouldAddOverlay  = no
    @visibleTooltips   = []
    @displayedTooltips = []
    @stepByStepGroups  = {}

    KD.getSingleton("mainController").on "FrameworkIsReady", =>
      @init()

    @on "ShowIntroductionTooltip", (view) =>
      @createInstance view

  init: ->
    return unless KD.whoami() instanceof KD.remote.api.JAccount
    KD.remote.api.JIntroSnippet.fetchAll (err, snippets) =>
      return log err if err # TODO: error handling

      @introductionTooltipStatusStorage = new AppStorage "IntroductionTooltipStatus"
      @introductionTooltipStatusStorage.fetchStorage (storage) =>
        @introSnippets = snippets

        for snippet in snippets
          @shouldAddOverlay = yes if snippet.overlay is "yes"
          currentSnippets   = snippet.snippets
          if snippet.visibility is "stepByStep"
            @stepByStepGroups[snippet.title] = snippet
            @stepByStepGroups[snippet.title].currentIndex = 0
          for item, i in currentSnippets
            item.expiryDate = snippet.expiryDate
            item.visibility = snippet.visibility
            item.groupName  = snippet.title
            item.overlay    = @shouldAddOverlay
            if snippet.visibility is "stepByStep"
              item.index    = i
              item.nextItem = currentSnippets[i + 1]
              item.prevItem = currentSnippets[i - 1]
            @createInstance null, item

  createInstance: (parentView, data) ->
    assets = @getAssets parentView, data
    data   = assets.data

    return if not assets or @isExpired data.expiryDate
    return if data.visibility is "stepByStep" and data.index > @stepByStepGroups[data.groupName].currentIndex
    return if @displayedTooltips.indexOf(data.introId) > -1

    @displayedTooltips.push data.introId

    {parentView, tooltipView} = assets
    tooltip = new IntroductionTooltip {
      parentView
      tooltipView
    }
    , data

    if @visibleTooltips.indexOf(parentView.tooltip) is -1
      @visibleTooltips.push parentView.tooltip

    tooltip.on "IntroductionTooltipClosed", (hasNext) =>
      @close parentView.getOptions().introId
      parentView.tooltip.destroy()
      @visibleTooltips.splice @visibleTooltips.indexOf(tooltip), 1
      @overlay.remove() if @visibleTooltips.length is 0 and not hasNext

    tooltip.on "IntroductionTooltipNavigated", (tooltipData) =>
      {nextItem} = tooltipData
      return @overlay.remove() unless nextItem
      ++@stepByStepGroups[tooltipData.groupName].currentIndex
      @createInstance null, nextItem

    if data.overlay then @addOverlay() else @addLayers()

  isExpired: (expiryDate) ->
    return new Date(expiryDate).getTime() < @currentTimestamp

  getAssets: (parentView, data) ->
    return no if not @introSnippets

    introData = data or @getIntroData parentView # make sure we have the data
    if not data and introData # we just know the intro view and should find the data, called from viewAppended
      @setData introData
      data = introData
    return no unless data # we know introId but we have no JIntroSnippet for this view, should return

    {introId} = data # we have an intro view and data for this view, go on!
    @storage  = @introductionTooltipStatusStorage # to store tooltip status
    return no if @shouldNotDisplay introId # user has already closed this introduction before, so don't show it again

    parentView = parentView or @getParentView data # we came from db query and don't know the view, should find
    return no unless parentView # view not appended to dom yet, probably came from db query

    tooltipView = null
    try
      tooltipView = eval Encoder.htmlDecode data.snippet.split("@").join("this.") # trying to eval snippet
    catch err
      log err.message
    return no unless tooltipView instanceof KDView # we will add this as a subview, should be a KDView instance

    return { parentView, tooltipView, data }

  shouldNotDisplay: (introId) ->
    return @storage.getValue(introId) is yes

  getIntroData: (parentView) ->
    {introId} = parentView.getOptions()
    {introSnippets} = @
    ourSnippet = null
    for introSnippet in introSnippets
      for snippet in introSnippet.snippets
        if introId is snippet.introId
          ourSnippet = snippet
    return ourSnippet

  getParentView: (data) ->
    return KD.introInstances[data.introId] or null

  close: (tooltipIntroId) ->
    @storage.setValue tooltipIntroId, yes

  addOverlay: ->
    return if @overlay
    @overlay = $ "<div/>",
      class : "kdoverlay"
    @overlay.hide()
    @overlay.appendTo "body"
    @overlay.fadeIn 200
    @overlay.bind "click", =>
      tooltipInstance.destroy() for tooltipInstance in @visibleTooltips
      @overlay.remove()
      @visibleTooltips.length = 0

  addLayers: ->
    windowController = KD.getSingleton("windowController")
    for tooltip in @visibleTooltips
      windowController.addLayer tooltip
      tooltip.on "ReceivedClickElsewhere", =>
        tooltip.destroy() for tooltip in @visibleTooltips when tooltip
        @visibleTooltips.length = 0