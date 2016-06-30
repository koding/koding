kd = require 'kd'
KDViewController = kd.ViewController
OnboardingItemView = require './onboardingitemview'
OnboardingTask = require './onboardingtask'

###*
 * View controller that manages item views on the current page
###
module.exports = class OnboardingViewController extends KDViewController

  constructor: (options = {}, data) ->

    super options, data

    @itemViews = {}


  ###*
   * Creates and renders views for onboarding items.
   * Item views are grouped by onboarding name.
   * If item views already exist for onboarding,
   * it just refreshes them.
   *
   * @param {string} name     - onboarding name
   * @param {Array} items     - a list of onboarding items
   * @param {isModal} isModal - a flag shows if onboarding is running on the modal
  ###
  runItems: (name, items, isModal = no) ->

    return  unless items.length
    return new OnboardingTask views, 'refresh'  if views = @itemViews[name]

    @itemViews[name] = views = []
    for item in items
      view = new OnboardingItemView { onboardingName: name, isModal }, item
      @bindViewEvents view
      views.push view

    new OnboardingTask views, 'render'


  ###*
   * Binds to item view events
  ###
  bindViewEvents: (view) ->

    view.on 'OnboardingItemCompleted', =>
      { onboardingName } = view.getOptions()
      viewData           = view.getData()
      itemViews          = @itemViews[onboardingName]
      for itemView, index in itemViews when itemView is view
        itemViews.splice index, 1
        break
      @emit 'OnboardingItemCompleted', onboardingName, viewData


  ###*
   * Refreshes item views according to the state of elements
   * they are attached to.
   *
   * @param {string} name - onboarding name
  ###
  refreshItems: (name) ->

    for own _name, views of @itemViews
      if _name is name or not name
        view.refresh()  for view in views


  ###*
   * Removes item views by onboarding name
   * If group name is passed, it removes only item views for that group.
   * Otherwise, it removes all item views.
   *
   * @param {string} name - onboarding name
  ###
  clearItems: (name) ->

    for own _name, views of @itemViews
      if _name is name or not name
        view.destroy()  for view in views

    if name
      delete @itemViews[name]
    else
      @itemViews = {}


  ###*
   * Hides all onboarding items
  ###
  hideItems: ->

    for own name, views of @itemViews
      view.removeThrobber()  for view in views
