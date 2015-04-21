kd = require 'kd'
KDViewController = kd.ViewController
OnboardingItemView = require './onboardingitemview'
OnboardingMetrics = require './onboardingmetrics'
showNotification = require 'app/util/showNotification'


module.exports = class OnboardingViewController extends KDViewController

  ###*
   * View controller that manages item views for onboarding group
  ###
  constructor: (options = {}, data) ->

    super options, data

    {@groupName, @slug} = @getOptions()
    @items              = @getData().items.slice()
    @startTrackDate     = new Date()

    @show @items.first


  ###*
   * Renders onboarding item view and binds to its events
   *
   * @param {OnboardingItemView} item - onboarding item view
  ###
  show: (item) ->

    view = new OnboardingItemView { @groupName, @items }, item
    @bindViewEvents view
    view.render()


  ###*
   * Shows another onboarding item in group depending on the given direction
   *
   * @param {string} direction - direction of the onboarding navigation. Possible values are 'prev' and 'next'
   * @param {object} itemData  - data of onboarding item view that requested onboarding navigation
  ###
  navigate: (direction, itemData) ->

    index = @items.indexOf itemData
    item  = if direction is 'next' then @items[++index] else @items[--index]
    @show item


  ###*
   * Binds to onboarding item view events
   *
   * @param {OnboardingItemView} view - view which events are necessary to listen
  ###
  bindViewEvents: (view) =>

    view.on 'NavigationRequested', (direction) =>
      @navigate direction, view.getData()

    view.on ['OnboardingCompleted', 'OnboardingCancelled'], @bound 'handleOnboardingEnded'
    view.on 'OnboardingFailed', @lazyBound 'handleOnboardingFailed', view


  ###*
   * If current item can't be shown, we need to show next onboarding item
   * If current item is the last one, it executes end stuff
   *
   * @param {OnboardingItemView} view  - onboarding item view that failed to be shown
  ###
  handleOnboardingFailed: (view) ->

    itemData = view.getData()
    index = @items.indexOf itemData
    @items.splice index, 1
    if view.isLast
      @handleOnboardingEnded()
    else
      @show @items[index]


  ###*
   * At the end of onboarding it's necessary to track the total tracked time
   * and emit an event to tell that onboarding has been ended
   *
   * @emits OnboardingEnded
  ###
  handleOnboardingEnded: ->

    trackedTime = new Date() - @startTrackDate
    OnboardingMetrics.trackCompleted @groupName, 'Total', trackedTime
    @emit 'OnboardingEnded', @slug
