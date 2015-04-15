htmlencode = require 'htmlencode'
$ = require 'jquery'
trackEvent = require '../util/trackEvent'
kd = require 'kd'
KDButtonView = kd.ButtonView
KDCustomHTMLView = kd.CustomHTMLView
KDSpotlightView = kd.SpotlightView
KDView = kd.View
OnboardingContextMenu = require '../onboardingcontextmenu'


module.exports = class OnboardingItemView extends KDView

  constructor: (options = {}, data) ->

    super options, data

    data                 = @getData()
    {@items, groupName}  = @getOptions()
    path                 = data.path
    itemName             = data.name
    index                = @items.indexOf data
    length               = @items.length - 1
    @isLast              = index is length
    @hasNext             = not @isLast
    @hasPrev             = index isnt 0 and @hasNext

    try
      path = htmlencode.htmlDecode path
      @parentElement = document.querySelector path

      if @parentElement instanceof Node
        @parentElement = @getKDViewFromElementNode @parentElement

      if @parentElement instanceof KDView and not @parentElement.hasClass 'hidden'
        @createContextMenu()
        @listenEvents()
      else
        console.warn "Target element should be an instance of KDView and should be visible", { groupName, itemName }
    catch e
      console.warn "Couldn't create onboarding item", { groupName, itemName, e }


  createContextMenu: ->

    @overlay      = new KDSpotlightView
      cssClass    : "onboarding-spotlight"
      isRemovable : no
      delegate    : @parentElement

    @contextMenu       = new OnboardingContextMenu
      cssClass         : "onboarding-wrapper"
      sticky           : yes
      menuMaxWidth     : 500
      menuWidth        : 500
      delegate         : @parentElement
    , customView       : @createContentView()

    @contextMenu.on "viewAppended", =>
      @contextMenu.once "KDObjectWillBeDestroyed", =>
        @destroy()

      kd.utils.defer =>
        $("body").addClass "noscroll"


  createContentView: ->

    {title, content} = @getData()
    title          = new KDCustomHTMLView { tagName     : "h3", partial  : title          }
    content        = new KDCustomHTMLView { tagName     : "p" , partial  : content        }
    buttonsWrapper = new KDCustomHTMLView { cssClass    : "buttons"                       }
    view           = new KDCustomHTMLView { cssClass    : "onboarding-item"               }
    closeButton    = new KDCustomHTMLView
      cssClass     : "close-icon"
      click        : => @emit "OnboardingCancelled"

    if @hasPrev
      prevButton   = new KDButtonView
        cssClass   : "solid compact light-gray"
        title      : "PREV"
        callback   : => @emit "NavigationRequested", "prev"

    if @hasNext
      nextButton   = new KDButtonView
        cssClass   : "solid green compact"
        title      : "NEXT"
        callback   : => @emit "NavigationRequested", "next"

    if @isLast
      doneButton   = new KDButtonView
        cssClass   : "solid green compact"
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


  getKDViewFromElementNode: (element) ->

    kdview  = null

    for key, kdinstance of kd.instances
      if kdinstance.getElement?() is element
        kdview = kdinstance
        break

    return kdview


  listenEvents: ->

    @on "NavigationRequested", (direction) =>
      @destroy()
      trackEvent "Onboarding navigation, click"

    @on "OnboardingCompleted", =>
      @destroy()
      @emitShownEvent()
      trackEvent "Onboarding navigation, success"

    @on "OnboardingCancelled", =>
      @destroy()
      @emitShownEvent()
      trackEvent "Onboarding navigation, failure"


  emitShownEvent: ->

    { slug } = @getOptions()
    @emit "OnboardingShown", slug


  destroy: ->

    super
    @overlay?.destroy()
    @contextMenu.destroy()
    $("body").removeClass "noscroll"




