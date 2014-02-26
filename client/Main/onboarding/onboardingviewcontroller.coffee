class OnboardingViewController extends KDController

  constructor: (options = {}, data) ->

    super options, data

    {@app}   = @getOptions()
    {@items} = @getData()

    @show @items.first
    @on "NavigationRequested", (direction, itemData) =>
      @contextMenu.destroy()
      @navigate direction, itemData

    @on "OnboardingCompleted", =>
      @contextMenu.destroy()

  navigate: (direction, itemData) ->
    index = @items.indexOf itemData
    item  = if direction is "next" then @items[++index] else @items[--index]
    @show item

  show: (item) ->
    path     = item.path
    appName  = @app.getOptions().name
    itemName = item.name
    index    = @items.indexOf item
    length   = @items.length - 1
    isLast   = index is   length
    hasNext  = not isLast
    hasPrev  = index isnt 0 and hasNext

    try
      parentElement = eval path
      if parentElement instanceof KDView
        delegate     = this
        options      = { delegate, parentElement, @app, hasNext, hasPrev, isLast }
        @contextMenu = new JContextMenu
          cssClass     : "onboarding-wrapper"
          sticky       : yes
          arrow        :
            placement  : "top"
          menuMaxWidth : 500
          menuWidth    : 500
          delegate     : parentElement
          x            : parentElement.getX() - 20
          y            : parentElement.getY() + 40
        , customView   : new OnboardingItemView options, item

        @contextMenu.on "viewAppended", =>
          KD.utils.defer =>
            @contextMenu.arrow.setCss "left", parentElement.getX() - @contextMenu.getX() + 10
      else
        details  = { appName: appName, itemName: itemName }
        console.warn "Parent element is not a KDView instance", details
    catch e
      details = { appName: appName, itemName: itemName, error: e }
      console.warn "Path parse error for onboarding item", details
