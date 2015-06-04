kd = require 'kd'
KDViewController = kd.ViewController
OnboardingItemView = require './onboardingitemview'
OnboardingMetrics = require './onboardingmetrics'
showNotification = require 'app/util/showNotification'
OnboardingTask = require './onboardingtask'

###*
 * View controller that manages item views on the current page
###
module.exports = class OnboardingViewController extends KDViewController

  constructor: (options = {}, data) ->

    super options, data

    @itemViews = {}


  ###*
   * Creates and renders views for onboarding items
   * Item views are grouped by onboarding group name.
   * If item views already exist for onboarding group,
   * it just refreshes them
   *
   * @param {string} groupName - name of onboarding group
   * @param {Array} items      - a list of onboarding items
   * @param {isModal} isModal  - a flag shows if onboarding is running on the modal
  ###
  runItems: (groupName, items, isModal = no) ->

    if @itemViews[groupName]
      @refreshItems groupName
    else
      @itemViews[groupName] = views = []
      for item in items
        view = new OnboardingItemView { groupName, isModal }, item
        @bindViewEvents view
        views.push view

      new OnboardingTask views, 'render'


  ###*
   * Binds to item view events
  ###
  bindViewEvents: (view) ->

    view.on 'OnboardingItemCompleted', =>
      { groupName } = view.getOptions()
      viewData      = view.getData()
      itemViews     = @itemViews[groupName]
      for itemView, index in itemViews when itemView is view
        itemViews.splice index, 1
        break
      @emit 'OnboardingItemCompleted', groupName, viewData


  ###*
   * Refreshes item views according to the state of elements
   * they are attached to.
   *
   * @param {string} groupName - name of onboarding group
  ###
  refreshItems: (groupName) ->

    views = @itemViews[groupName]
    return  unless views

    new OnboardingTask views, 'refresh'


  ###*
   * Removes item views by onboarding group
   * If group name is passed, it removes only item views for that group.
   * Otherwise, it removes all item views.
   *
   * @param {string} groupName - name of onboarding group
  ###
  clearItems: (groupName) ->

    for _groupName, views of @itemViews
      if _groupName is groupName or not groupName
        view.destroy()  for view in views

    if groupName
      delete @itemViews[groupName]
    else
      @itemViews = {}


  ###*
   * Hides all onboarding items
  ###
  hideItems: ->

    for groupName, views of @itemViews
      view.hide()  for view in views
