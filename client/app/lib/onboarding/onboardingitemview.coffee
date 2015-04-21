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

  ###*
   * A view that renders onboarding tooltip and highlights target element
   * for onboarding item
  ###
  constructor: (options = {}, data) ->

    super options, data

    data                 = @getData()
    {@items, @groupName} = @getOptions()
    @itemName            = data.name
    index                = @items.indexOf data
    @isLast              = index is @items.length - 1
    @hasNext             = not @isLast
    @hasPrev             = index isnt 0


  ###*
   * Tries to find a target element in DOM
   * If it's found, renders onboarding tooltip for it
   * Otherwise, emits an event to let know that onboarding item can't be shown
   *
   * @emits OnboardingFailed
  ###
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


  ###*
   * Renders onboarding tooltip with OnboardingContextMenu
   * and highlights a target element with KDSpotlightView
  ###
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


  ###*
   * Creates subviews for the content of onboarding tooltip
   *
   * @return {KDCustomHTMLView} - onboarding item's content view
  ###
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


  ###*
   * Searches for a target element by path
   * If the element is in DOM, tries to find a kd instance for it
   *
   * @param {string} path - path to element
   * @return {KDView} - kd view for the path if it exists
  ###
  getViewByPath: (path) ->

    path = htmlencode.htmlDecode path
    element = document.querySelector path

    return  unless element

    for key, kdinstance of kd.instances
      if kdinstance.getElement?() is element
        return kdinstance


  ###*
   * It is executed when user clicks on Prev or Next button
   * It tracks onboarding item completion and emits event
   * to let know that prev/next onboarding item is requested
   *
   * @param {string} direction - direction of the onboarding navigation. Possible values are 'prev' and 'next'
   * @emits NavigationRequested
  ###
  requestNavigation: (direction) ->

    @destroy()
    OnboardingMetrics.trackCompleted @groupName, @itemName, @getTrackedTime()
    @emit 'NavigationRequested', direction


  ###*
   * It is executed when user clicks on Done button
   * It tracks onboarding item completion and emits event
   * to let know that onboarding is finished
   *
   * @emits OnboardingCompleted
  ###
  complete: ->

    @destroy()
    OnboardingMetrics.trackCompleted @groupName, @itemName, @getTrackedTime()
    @emit 'OnboardingCompleted'


  ###*
   * It is executed when user closes onboarding tooltip
   * It tracks onboarding item cancellation and emits event
   * to let know that onboarding is cancelled
   *
   * @emits OnboardingCancelled
  ###
  cancel: ->

    @destroy()
    OnboardingMetrics.trackCancelled @groupName, @itemName
    @emit 'OnboardingCancelled'


  ###*
   * Returns time spent from the moment when onboarding item was started
   * till the current time
   *
   * @return {number} - number of milliseconds
  ###
  getTrackedTime: -> new Date() - @startTrackDate


  ###*
   * Destroys the tooltip and all its subviews
  ###
  destroy: ->

    super
    @overlay?.destroy()
    @contextMenu.destroy()
    $('body').removeClass 'noscroll'




