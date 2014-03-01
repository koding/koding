class OnboardingItemView extends KDView

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
      @parentElement = eval Encoder.htmlDecode path
      if @parentElement instanceof KDView
        @createContextMenu()
        @listenEvents()
      else if @parentElement instanceof jQuery
        @parentElement = @getKDViewFromJQueryElement @parentElement
        return  unless @parentElement

        @createContextMenu()
        @listenEvents()
      else
        console.warn "Target element should be an instance of KDView or jQuery", { appName, itemName }
    catch e
      console.warn "Path parse error for onboarding item", { appName, itemName, e }

  createContextMenu: ->
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
    @overlay       = new KDSpotlightView  { isRemovable : no,   delegate : @parentElement }
    title          = new KDCustomHTMLView { tagName     : "h3", partial  : title          }
    content        = new KDCustomHTMLView { tagName     : "p" , partial  : content        }
    buttonsWrapper = new KDCustomHTMLView { cssClass    : "buttons"                       }
    view           = new KDCustomHTMLView { cssClass    : "onboarding-item"               }
    closeButton    = new KDCustomHTMLView
      cssClass     : "close-icon"
      click        : => @emit "OnboardingCancelled"

    if @hasPrev
      prevButton   = new KDButtonView
        cssClass   : "solid ufak light-gray"
        title      : "PREV"
        callback   : => @emit "NavigationRequested", "prev"

    if @hasNext
      nextButton   = new KDButtonView
        cssClass   : "solid green ufak"
        title      : "NEXT"
        callback   : => @emit "NavigationRequested", "next"

    if @isLast
      doneButton   = new KDButtonView
        cssClass   : "solid green ufak"
        title      : "DONE"
        callback   : => @emit "OnboardingCompleted"

    if @items.length > 1
      stepsWrapper = new KDCustomHTMLView
        cssClass   : "steps"

      for item in @items
        stepsWrapper.addSubView new KDCustomHTMLView
          tagName  : "span"
          cssClass : if item is @getData() then "active" else ""

    for child in [ prevButton, nextButton, doneButton, stepsWrapper ] when child
      buttonsWrapper.addSubView child

    for child in [ title, content, buttonsWrapper, closeButton ] when child
      view.addSubView child

    return view

  getKDViewFromJQueryElement: ($element) ->
    element = $element[0] # first is jQuery method
    kdview  = null

    for key, kdinstance of KD.instances
      if kdinstance.getElement?() is element
        kdview = kdinstance

    return kdview

  listenEvents: ->
    @on "NavigationRequested", (direction) =>
      @destroy()
      @getDelegate().emit "NavigationRequested", direction, @getData()

    @on "OnboardingCompleted", =>
      @destroy()

    @on "OnboardingCancelled", =>
      @destroy()

    {setStorage, slug} = @getOptions()
    if setStorage
      viewController = @getDelegate()
      onboardingController = viewController.getDelegate()
      onboardingController.emit "OnboardingShown", slug

  destroy: ->
    super
    @overlay?.destroy()
    @contextMenu.destroy()
