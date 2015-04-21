kd = require 'kd'
KDViewController = kd.ViewController
OnboardingItemView = require './onboardingitemview'
OnboardingMetrics = require './onboardingmetrics'
showNotification = require 'app/util/showNotification'


module.exports = class OnboardingViewController extends KDViewController

  constructor: (options = {}, data) ->

    super options, data

    {@groupName, @slug} = @getOptions()
    @items              = @getData().items.slice()
    @startTrackDate     = new Date()

    @show @items.first


  show: (item) ->

    view = new OnboardingItemView { @groupName, @items }, item
    @bindViewEvents view
    view.render()


  navigate: (direction, itemData) ->

    index = @items.indexOf itemData
    item  = if direction is 'next' then @items[++index] else @items[--index]
    @show item


  bindViewEvents: (view) =>

    view.on 'NavigationRequested', (direction) =>
      @navigate direction, view.getData()

    view.on 'OnboardingCompleted', @bound 'handleOnboardingEnded'

    view.on 'OnboardingCancelled', =>
      @handleOnboardingEnded()
      showNotification 'You can access it anytime by pressing F1',
        type     : 'main'
        duration : 1500

    view.on 'OnboardingFailed', =>
      # if onboarding item can't be shown, skip it and move to the next
      itemData = view.getData()
      index = @items.indexOf itemData
      @items.splice index, 1
      if view.isLast
        view.emit 'OnboardingCompleted'
      else
        @show @items[index]


  handleOnboardingEnded: ->

    trackedTime = new Date() - @startTrackDate
    OnboardingMetrics.trackCompleted @groupName, 'Total', trackedTime
    @emit 'OnboardingEnded', @slug
