kd = require 'kd'
KDViewController = kd.ViewController
OnboardingItemView = require './onboardingitemview'
OnboardingMetrics = require './onboardingmetrics'
showNotification = require 'app/util/showNotification'

###*
 * View controller that manages item views on the current page
###
module.exports = class OnboardingViewController extends KDViewController

  constructor: (options = {}, data) ->

    super options, data

    @itemViews = {}

  ###*
   * Creates and renders views for onboarding items
   * Item views are are grouped by onboarding group name.
   * If item views already exist for onboarding group,
   * the method does nothing to avoid running the same items multiple times
   *
   * @param {string} groupName - name of onboarding group
   * @param {Array} items      - a list of onboarding items
   * @param {isModal} isModal  - a flag shows if onboarding is running on the modal
  ###
  runItems: (groupName, items, isModal) ->

    return  if @itemViews[groupName]

    @itemViews[groupName] = []
    for item in items
      view = new OnboardingItemView { groupName, isModal }, item
      view.render()
      @bindViewEvents view
      @itemViews[groupName].push view


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
   * Refreshes item views according to visibility of elements
   * they are attached to
  ###
  refreshItems: ->

    for groupName, views of @itemViews
      view.refreshVisiblity()  for view in views


  ###*
   * Removes item views by onboarding group
   * If group name is not passed, it removed all item views
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
