htmlencode = require 'htmlencode'
$ = require 'jquery'
kd = require 'kd'
KDButtonView = kd.ButtonView
KDCustomHTMLView = kd.CustomHTMLView
KDSpotlightView = kd.SpotlightView
KDView = kd.View
OnboardingContextMenu = require '../onboardingcontextmenu'
OnboardingMetrics = require './onboardingmetrics'


module.exports = class OnboardingItemView extends KDView

  ESC_KEY = 27

  constructor: (options = {}, data) ->

    super options, data

    data                 = @getData()
    {@items, @groupName} = @getOptions()
    @itemName            = data.name
    index                = @items.indexOf data
    @isLast              = index is @items.length - 1
    @hasNext             = not @isLast
    @hasPrev             = index isnt 0 and @hasNext


  render: ->

    { path } = @getData()

    try
      @targetElement = @getViewByPath path

      if @targetElement and not @targetElement.hasClass 'hidden'
        @createContextMenu()
        @startTrackDate = new Date()
      else
        console.warn 'Target element should be an instance of KDView and should be visible', { @groupName, @itemName }
        @emit 'OnboardingFailed'
    catch e
      console.warn "Couldn't create onboarding item", { @groupName, @itemName, e }
      @emit 'OnboardingFailed'


  createContextMenu: ->

    @overlay       = new KDSpotlightView
      cssClass     : 'onboarding-spotlight'
      isRemovable  : no
      delegate     : @targetElement

    @contextMenu   = new OnboardingContextMenu
      cssClass     : 'onboarding-wrapper'
      sticky       : yes
      menuMaxWidth : 500
      menuWidth    : 500
      delegate     : @targetElement
    , customView   : @createContentView()

    @contextMenu.on 'viewAppended', =>
      @contextMenu.once 'KDObjectWillBeDestroyed', =>
        @destroy()

      kd.utils.defer =>
        $('body').addClass 'noscroll'

    @contextMenu.treeController.on 'keyEventPerformedOnTreeView', (event) =>
      @cancel()  if event.which is ESC_KEY


  createContentView: ->

    {title, content} = @getData()
    title          = new KDCustomHTMLView { tagName     : 'h3', partial  : title          }
    content        = new KDCustomHTMLView { tagName     : 'p' , partial  : content        }
    buttonsWrapper = new KDCustomHTMLView { cssClass    : 'buttons'                       }
    view           = new KDCustomHTMLView { cssClass    : 'onboarding-item'               }
    closeButton    = new KDCustomHTMLView
      cssClass     : 'close-icon'
      click        : @bound 'cancel'

    if @hasPrev
      prevButton   = new KDButtonView
        cssClass   : 'solid compact light-gray'
        title      : 'PREV'
        callback   : @lazyBound 'requestNavigation', 'prev'

    if @hasNext
      nextButton   = new KDButtonView
        cssClass   : 'solid green compact'
        title      : 'NEXT'
        callback   : @lazyBound 'requestNavigation', 'next'

    if @isLast
      doneButton   = new KDButtonView
        cssClass   : 'solid green compact'
        title      : 'DONE'
        callback   : @bound 'complete'

    if @items.length > 1
      stepsWrapper = new KDCustomHTMLView
        cssClass   : 'steps'

      for item in @items
        stepsWrapper.addSubView new KDCustomHTMLView
          tagName  : 'span'
          cssClass : if item is @getData() then 'active' else ''

    for child in [ prevButton, nextButton, doneButton, stepsWrapper ] when child
      buttonsWrapper.addSubView child

    for child in [ title, content, buttonsWrapper, closeButton ] when child
      view.addSubView child

    return view


  getViewByPath: (path) ->

    path = htmlencode.htmlDecode path
    element = document.querySelector path

    return  unless element

    for key, kdinstance of kd.instances
      if kdinstance.getElement?() is element
        return kdinstance


  requestNavigation: (direction) ->

    @destroy()
    OnboardingMetrics.trackCompleted @groupName, @itemName, @getTrackedTime()
    @emit 'NavigationRequested', direction


  complete: ->

    @destroy()
    OnboardingMetrics.trackCompleted @groupName, @itemName, @getTrackedTime()
    @emit 'OnboardingCompleted'


  cancel: ->

    @destroy()
    OnboardingMetrics.trackCancelled @groupName, @itemName
    @emit 'OnboardingCancelled'


  getTrackedTime: -> new Date() - @startTrackDate


  destroy: ->

    super
    @overlay?.destroy()
    @contextMenu.destroy()
    $('body').removeClass 'noscroll'




