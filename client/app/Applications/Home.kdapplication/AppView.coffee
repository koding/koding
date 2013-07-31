class HomeAppView extends KDView

  constructor:(options = {}, data)->

    super options, data

  _windowDidResize:->
    @unsetClass "extra-wide wide medium narrow extra-narrow"
    w = @getWidth()
    @setClass if w > 1500    then ""
    else if 1000 < w < 1500  then "extra-wide"
    else if 800  < w < 1000  then "wide"
    else if 600  < w < 800   then "medium"
    else if 480  < w < 600   then "narrow"
    else "extra-narrow"

  viewAppended:->

    account = KD.whoami()

    @addSubView @featuredActivities = new FeaturedActivitiesContainer
    # @addSubView @footer = new KDCustomHTMLView tagName : 'footer'

    @emit 'ready'

    @utils.wait 500, => @_windowDidResize()
    KD.getSingleton("contentPanel").on "transitionend", (event)=>
      event.stopPropagation()
      @_windowDidResize()  if $(event.target).is "#content-panel"
