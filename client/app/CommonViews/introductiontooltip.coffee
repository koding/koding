class IntroductionTooltip extends KDObject

  constructor: (options = {}, data) ->

    super options, data

    {tooltipView, parentView} = @getOptions()

    tooltipView.addSubView @closeButton = new KDCustomHTMLView
      tagName  : "span"
      cssClass : "close-icon"
      click    : => @close()

    parentView.setTooltip
      view     : tooltipView
      cssClass : "introduction-tooltip"
      sticky   : yes

    @utils.defer =>
      parentView.tooltip.show()

  close: ->
    @emit "IntroductionTooltipClosed"


class IntroductionTooltipController extends KDController

  constructor: (options = {}, data) ->

    super options, data

    @shouldAddOverlay = no
    @visibleTooltips  = []

    @getSingleton("mainController").on "FrameworkIsReady", =>
      @init()

  init: ->
    KD.remote.api.JIntroSnippet.fetchAll (err, snippets) =>
      return log err if err # TODO: error handling

      @introductionTooltipStatusStorage = new AppStorage "IntroductionTooltipStatus"
      @introductionTooltipStatusStorage.fetchStorage (storage) =>
        @introSnippets = snippets
        for snippet in snippets
          @shouldAddOverlay = yes if snippet.overlay
          for item in snippet.snippets
            item.expiryDate = snippet.expiryDate
            @createInstance null, item

        # @addOverlay() if @shouldAddOverlay and @visibleTooltips.length > 0

  createInstance: (parentView, data) ->
    assets = @getAssets parentView, data
    return unless assets

    {parentView, tooltipView} = assets
    tooltip = new IntroductionTooltip {
      parentView
      tooltipView
    }
    , assets.data

    @visibleTooltips.push tooltip

    tooltip.on "IntroductionTooltipClosed", =>
      @close parentView.getOptions().introId
      parentView.tooltip.destroy()
      @visibleTooltips.splice @visibleTooltips.indexOf(tooltip), 1

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
    try tooltipView = eval Encoder.htmlDecode data.snippet.split("@").join("this.") # trying to eval snippet
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
    @overlay = $ "<div/>",
      class : "kdoverlay"
    @overlay.hide()
    @overlay.appendTo "body"
    @overlay.fadeIn 200
