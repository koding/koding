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
    @itemViews          = []

    items               = @getData().items.slice()

    @showItem item for item in items


  ###*
   * Renders onboarding item view and binds to its events
   *
   * @param {OnboardingItemView} item - onboarding item view
  ###
  showItem: (item) ->

    view = new OnboardingItemView { @groupName }, item
    view.render()
    @itemViews.push view


  destroy: ->

    view.destroy() for view in @itemViews
    super
