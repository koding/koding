remote = require('../remote')
isLoggedIn = require '../util/isLoggedIn'
kd = require 'kd'
whoami = require 'app/util/whoami'
checkFlag = require 'app/util/checkFlag'
KDController = kd.Controller
OnboardingEvent = require './onboardingevent'
OnboardingViewController = require './onboardingviewcontroller'
OnboardingConstants = require './onboardingconstants'

###*
 * A controller that manages onboardings for the current user
###
module.exports = class OnboardingController extends KDController

  constructor: (options = {}, data) ->

    super options, data

    @onboardings    = {}
    @pendingQueue   = []
    @isReady        = no
    @viewController = new OnboardingViewController()

    { mainController, windowController, appManager } = kd.singletons

    # if isLoggedIn() then @fetchItems()
    # else
    #   mainController.on 'accountChanged.to.loggedIn', @bound 'fetchItems'

    appManager.on 'FrontAppIsChanged', @bound 'handleFrontAppChanged'

    @viewController.on 'OnboardingItemCompleted', @bound 'handleItemCompleted'

    @ready()

  # ###*
  #  * Fetches onboardings from DB
  #  * Preview mode is always enabled for super admin, so super admin always gets onboardings on preview
  #  * Other users receive published onboardings
  # ###
  # fetchItems: ->

  #   { STORAGE_NAME, STORAGE_VERSION } = OnboardingConstants

  #   account           = whoami()
  #   @registrationDate = new Date(account.meta.createdAt)
  #   @appStorage       = kd.getSingleton('appStorageController').storage STORAGE_NAME, STORAGE_VERSION
  #   query             = { partialType : 'ONBOARDING' }

  #   if @isPreviewMode()
  #   then query.isPreview = yes
  #   else query.isActive  = yes

  #   remote.api.JCustomPartials.some query, {}, (err, onboardings) =>
  #     return kd.warn err  if err

  #     for data in onboardings when data.partial
  #       @onboardings[data.name] = data

  #     @appStorage.fetchStorage @bound 'ready'


  ###*
   * It is executed once all data is loaded.
   * It marks controller as ready to work and runs all onboardings
   * which were requested while data was loading and therefore
   * were added to pending queue
  ###
  ready: ->

    @isReady = yes
    @run args...  for args in @pendingQueue


  ###*
   * Runs onboarding by name.
   * If controller is not ready yet, onboarding request is added to pending queue.
   * Onboarding can be run if it was not shown for the current user yet
   * and user was registered after onboarding had been published.
   * Also, it can be shown if it was requested to show it again (reset onboarding).
   * A list of onboarding items should be saved to appStorage in order
   * to understand what items are left to show for the user next time
   *
   * @param {string} name      - onboarding name
   * @param {isModal} isModal  - a flag shows if onboarding is running on the modal.
   * In this case onboarding items should have higher z-index
  ###
  run: (name, isModal) ->

    return @pendingQueue.push [].slice.call(arguments)  unless @isReady

    @refresh()

    onboarding = @onboardings[name]
    return  unless onboarding
    return  unless onboarding.partial.items?.length

    items   = @getItemsIfResetOnboarding onboarding
    isReset = items?

    items      = @getItemsIfNewUser onboarding  unless items
    needUpdate = items?

    items = @getItemsLeftToRun onboarding  unless items

    @viewController.runItems name, items, isModal

    @removeFromResetOnboardings onboarding.name  if isReset

    if needUpdate
      itemSlugs = @convertToSlugs items
      @updateItemSlugs name, itemSlugs


  ###*
   * Returns onboarding items if onboarding was reset
   *
   * @param {object} onboarding
   * @return {Array}
  ###
  getItemsIfResetOnboarding: (onboarding) ->

    return  unless @isResetOnboarding onboarding.name

    items = onboarding.partial.items
    items = []  unless Array.isArray items
    return items


  ###*
   * Returns onboarding items if user is new and have never seen onboarding
   *
   * @param {object} onboarding
   * @return {Array}
  ###
  getItemsIfNewUser: (onboarding) ->

    isNewUserForOnboarding = onboarding.publishedAt and (new Date(onboarding.publishedAt) < @registrationDate)
    neverSeenOnboarding    = not @getSavedItemSlugs onboarding.name

    return onboarding.partial.items  if isNewUserForOnboarding and neverSeenOnboarding


  ###*
   * Returns onboarding items left to run for the user, i.e. all items of onboarding
   * excluding those which user has already completed
   *
   * @param {object} onboarding
   * @return {Array}
  ###
  getItemsLeftToRun: (onboarding) ->

    items     = []
    itemSlugs = @getSavedItemSlugs onboarding.name

    return  unless itemSlugs

    for item in onboarding.partial.items
      itemSlug = kd.utils.slugify item.name
      items.push item  if itemSlugs.indexOf(itemSlug) > -1

    return items


  ###*
   * Returns a list of onboardings which were reset by user
   *
   * @return {Array}
  ###
  getResetOnboardings: ->

    list = @appStorage.getValue OnboardingConstants.RESET_ONBOARDINGS
    list = []  unless Array.isArray list
    return list


  ###*
   * Checks if onboarding was reset by user
   *
   * @param {string} name - onboarding name
   * @return {bool}
  ###
  isResetOnboarding: (name) -> @getResetOnboardings().indexOf(name) > -1


  ###*
   * Removes onboarding from the list of reset onboardings and saves changes to appStorage
   *
   * @param {string} name - onboarding name
  ###
  removeFromResetOnboardings: (name) ->

    resetOnboardings = @getResetOnboardings()

    if (index = resetOnboardings.indexOf name) > -1
      resetOnboardings.splice index, 1
      @appStorage.setValue OnboardingConstants.RESET_ONBOARDINGS, resetOnboardings


  ###*
   * Saves a list of currently available onboardings to appStorage
   * so when any onboarding is requested to run and it is in this list,
   * it will run without any other check
   *
   * @param {function} callback - it's called once the list is saved
  ###
  reset: (callback) ->

    events = []
    events.push event  for event in OnboardingEvent when @onboardings[event]?
    @appStorage.setValue OnboardingConstants.RESET_ONBOARDINGS, events, callback


  ###*
   * Refreshes onboarding items according to the state of elements
   * they are attached to. If elements are hidden, items get hidden too,
   * and vice versa.
   *
   * @param {string} name - name of onboarding which items should be refreshed
  ###
  refresh: (name) ->

    @viewController.refreshItems name


  ###*
   * Removes onboarding items from the page
   *
   * @param {string} name - onboarding name
  ###
  stop: (name) -> @viewController.clearItems name


  ###*
   * Handles FrontAppIsChanged event of appManager and hides all
   * onboarding items at that moment. If a new app has onboardings,
   * they will be run using run() later when the page is ready
   *
   * @param {object} appInstance     - new application
   * @param {object} prevAppInstance - previous application
  ###
  handleFrontAppChanged: (appInstance, prevAppInstance) ->

    @viewController.hideItems()


  ###*
   * Handles OnboardingItemCompleted event which is called when user completes
   * and closes onboarding item. In this case item should be removed from
   * the list of visible items and the list should be updated in appStorage
   * Every time onboarding runs on the page, it shows only items left
   * in the list. When no item is in the list, onboarding won't appear
   *
   * @param {string} name - onboarding name
   * @param {object} item - data of completed item
  ###
  handleItemCompleted: (name, item) ->

    itemSlugs = @getSavedItemSlugs name
    for itemSlug, index in itemSlugs when itemSlug is kd.utils.slugify item.name
      itemSlugs.splice index, 1
      break
    @updateItemSlugs name, itemSlugs


  ###*
   * Creates a slug for onboarding
   *
   * @param {string} name - onboarding name
   * @return {string}
  ###
  createOnboardingSlug: (name) ->

    kd.utils.slugify kd.utils.curry 'onboarding', name


  ###*
   * Returns a list of slugs for onboarding items
   *
   * @param {Array} items - onboarding items
   * @return {Array}
  ###
  convertToSlugs: (items) ->

    itemSlugs = (kd.utils.slugify item.name  for item in items)


  ###*
   * Returns a list of saved onboarding item slugs
   *
   * @param {string} name - onboarding name
   * @return {Array}
  ###
  getSavedItemSlugs: (name) ->

    slug   = @createOnboardingSlug name
    result = @appStorage.getValue slug

    return result  if result instanceof Array


  ###*
   * Updates in appStorage a list of onboarding item slugs
  ###
  updateItemSlugs: (name, itemSlugs, callback) ->

    slug = @createOnboardingSlug name
    @appStorage.setValue slug, itemSlugs, callback

  isPreviewMode: -> return checkFlag 'super-admin'
