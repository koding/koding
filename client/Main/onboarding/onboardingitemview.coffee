class OnboardingItemView extends JView

  constructor: (options = {}, data) ->

    super options, data

    data           = @getData()
    {@items, @app} = @getOptions()
    path           = data.path
    appName        = @app.getOptions().name
    itemName       = data.name
    index          = @items.indexOf data
    length         = @items.length - 1
    @isLast        = index is length
    @hasNext       = not @isLast
    @hasPrev       = index isnt 0 and @hasNext

    try
      @parentElement = eval path
      if @parentElement instanceof KDView
        @createContextMenu()
        @listenEvents()
      else
        console.warn "Parent element is not a KDView instance", { appName, itemName }
    catch e
      console.warn "Path parse error for onboarding item", { appName, itemName, e }

  createContextMenu: ->
    delegate       = this
    @contextMenu   = new JContextMenu
      cssClass     : "onboarding-wrapper"
      sticky       : yes
      arrow        :
        placement  : "top"
      menuMaxWidth : 500
      menuWidth    : 500
      delegate     : @parentElement
      x            : @parentElement.getX() - 20
      y            : @parentElement.getY() + 40
    , customView   : @createContentView()

    @contextMenu.on "viewAppended", =>
      KD.utils.defer =>
        left = @parentElement.getX() - @contextMenu.getX() + 10
        @contextMenu.arrow.setCss "left", left

  createContentView: ->
    {title, content} = @getData()
    @overlay       = new KDOverlayView    { isRemovable : no    , parent  : "body"  }
    title          = new KDCustomHTMLView { tagName     : "h3"  , partial : title   }
    content        = new KDCustomHTMLView { tagName     : "p"   , partial : content }
    buttonsWrapper = new KDCustomHTMLView { cssClass    : "buttons"                 }
    view           = new KDCustomHTMLView { cssClass    : "onboarding-item"         }

    if @hasPrev
      prevButton   = new KDButtonView
        cssClass   : "solid medium light-gray"
        title      : "PREV"
        callback   : => @emit "NavigationRequested", "prev"

    if @hasNext
      nextButton   = new KDButtonView
        cssClass   : "solid medium green"
        title      : "NEXT"
        callback   : => @emit "NavigationRequested", "next"

    if @isLast
      doneButton   = new KDButtonView
        cssClass   : "solid medium green"
        title      : "DONE"
        callback   : => @emit "OnboardingCompleted"

    for button in [ prevButton, nextButton, doneButton ] when button
      buttonsWrapper.addSubView button

    for child  in [ title, content, buttonsWrapper ]
      view.addSubView child

    return view

  listenEvents: ->
    @on "NavigationRequested", (direction) =>
      @overlay.destroy()
      @contextMenu.destroy()
      @getDelegate().emit "NavigationRequested", direction, @getData()

    @on "OnboardingCompleted", =>
      @overlay.destroy()
      @contextMenu.destroy()
