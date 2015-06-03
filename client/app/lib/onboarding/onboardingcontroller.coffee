remote = require('../remote').getInstance()
isLoggedIn = require '../util/isLoggedIn'
$ = require 'jquery'
kd = require 'kd'
whoami = require 'app/util/whoami'
checkFlag = require 'app/util/checkFlag'
KDController = kd.Controller
OnboardingViewController = require './onboardingviewcontroller'
OnboardingEvent = require './onboardingevent'
OnboardingConstants = require './onboardingconstants'
Promise = require 'bluebird'

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

    if isLoggedIn() then @fetchItems()
    else
      mainController.on 'accountChanged.to.loggedIn', @bound 'fetchItems'

    appManager.on 'FrontAppIsChanged', @bound 'handleFrontAppChanged'

    @viewController.on 'OnboardingItemCompleted', @bound 'handleItemCompleted'


  ###*
   * Fetches onboardings from DB
   * Preview mode is always enabled for super admin, so super admin always gets onboardings on preview
   * Other users receive published onboardings
  ###
  fetchItems: ->

    { STORAGE_NAME, STORAGE_VERSION } = OnboardingConstants

    account           = whoami()
    @registrationDate = new Date(account.meta.createdAt)
    @appStorage       = kd.getSingleton('appStorageController').storage STORAGE_NAME, STORAGE_VERSION
    query             = partialType : 'ONBOARDING'

    if @isPreviewMode()
    then query.isPreview = yes
    else query.isActive  = yes

    remote.api.JCustomPartials.some query, {}, (err, onboardings) =>
      return kd.warn err  if err

      for data in onboardings when data.partial
        @onboardings[data.name] = data

      @appStorage.fetchStorage @bound 'ready'


  ###*
   * It is executed once all data is loaded
   * If it's preview mode (super admin), it resets all onboardings so admin can see them again
   * Also, it runs all onboardings which were requested while data was loading
   * and therefore were added to pending queue
  ###
  ready: ->

    if @isPreviewMode()
      @resetOnboardings @bound 'processPendingQueue'
    else
      @processPendingQueue()


  ###*
   * Marks controller as ready to work and runs onboardings in pending queue
  ###
  processPendingQueue: ->

    @isReady = yes
    @runOnboarding args...  for args in @pendingQueue


  ###*
   * Runs onboarding group by name.
   * If controller is not ready yet, onboarding request is added to pending queue.
   * Onboarding can be run if it was not shown for the current user yet
   * and user was registered after onboarding had been published.
   * Also, it can be shown if it was requested to show it again (onboarding reset).
   * A list of onboarding group items is saved to appStorage before they run
   * so it's possible to understand what items are left to show for the user
   *
   * @param {string} groupName - name of onboarding group
   * @param {isModal} isModal  - a flag shows if onboarding is running on the modal.
   * In this case onboarding items should have higher z-index
   * @param {number} delay     - time to wait before running onboarding
  ###
  runOnboarding: (groupName, isModal, delay) ->

    return @pendingQueue.push [].slice.call(arguments)  unless @isReady

    onboarding = @onboardings[groupName]
    return  unless onboarding
    return  unless onboarding.partial.items?.length

    isForcedGroup = @useForcedGroup groupName
    isProperUser  = onboarding.publishedAt and new Date(onboarding.publishedAt) < @registrationDate
    itemSlugs     = @getItemsToRun groupName
    items         = []

    if isForcedGroup or (isProperUser and not itemSlugs)
      items     = onboarding.partial.items
      itemSlugs = @convertToSlugs items
      @updateItemsToRun groupName, itemSlugs
    else if itemSlugs
      for item in onboarding.partial.items
        itemSlug = kd.utils.slugify item.name
        items.push item  if itemSlugs.indexOf(itemSlug) > -1

    return  unless items.length

    @viewController.runItems groupName, items, isModal, delay


  ###*
   * Checks if onboarding group was reset before and therefore should be forcibly run
   * If so, it removes the group from a list of reset groups, saves the list
   * and return yes. Otherwise, it return no
   *
   * @param {string} groupName - name of checkable group
  ###
  useForcedGroup: (groupName) ->

    forcedGroups  = @appStorage.getValue OnboardingConstants.FORCED_ONBOARDINGS
    index         = forcedGroups?.indexOf groupName
    isForcedGroup = index > -1

    if isForcedGroup
      forcedGroups.splice index, 1
      @appStorage.setValue OnboardingConstants.FORCED_ONBOARDINGS, forcedGroups

    return isForcedGroup


  ###*
   * Saves a list of currently available onboardings to appStorage
   * so when any onboarding is requested to run and it is in this list,
   * it will run without any other check
   *
   * @param {function} callback - it's called once the list is saved
  ###
  resetOnboardings: (callback) ->

    events = []
    events.push event  for event of OnboardingEvent when @onboardings[event]?
    @appStorage.setValue OnboardingConstants.FORCED_ONBOARDINGS, events, callback

  ###*
   * Refreshes onboarding items according to the state of elements
   * they are attached to. If elements are hidden, items get hidden too,
   * and vice versa
   *
   * @param {string} groupName - name of onboarding group which items should be
   * refreshed. If groupName is null, all items should be refreshed
  ###
  refreshOnboarding: (groupName) -> @viewController.refreshItems groupName


  ###*
   * Removes onboarding group items from the page
   *
   * @param {string} groupName - name of onboarding group
  ###
  stopOnboarding: (groupName) -> @viewController.clearItems groupName


  ###*
   * Handles FrontAppIsChanged event of appManager and refreshes
   * onboarding items. Items on previous app should be hidden,
   * items on new app should become visible
   *
   * @param {object} appInstance     - new application
   * @param {object} prevAppInstance - previous application
  ###
  handleFrontAppChanged: (appInstance, prevAppInstance) ->

    kd.utils.defer @bound 'refreshOnboarding'


  ###*
   * Handles OnboardingItemCompleted event which is called when user completes
   * and closes onboarding item. In this case item should be removed from
   * the list of visible items and the list should be updated in appStorage
   * Every time onboarding runs on the page, it shows only items left
   * in the list. When no item is in the list, onboarding won't appear
   *
   * @param {string} groupName - name of onboarding group
   * @param {object} item      - data of completed item
  ###
  handleItemCompleted: (groupName, item) ->

    itemSlugs = @getItemsToRun groupName
    for itemSlug, index in itemSlugs when itemSlug is kd.utils.slugify item.name
      itemSlugs.splice index, 1
      break
    @updateItemsToRun groupName, itemSlugs


  ###*
   * Creates a slug for onboarding group
   *
   * @param {string} groupName - name of onboarding group
  ###
  createGroupSlug: (groupName) ->

    kd.utils.slugify kd.utils.curry 'onboarding', groupName


  ###*
   * Returns a list of slugs for onboarding items
   *
   * @param {Array} items - onboarding items
  ###
  convertToSlugs: (items) ->

    itemSlugs = kd.utils.slugify item.name  for item in items


  ###*
   * Returns a list of onboarding item slugs which are left to run
   * for onboarding group
   *
   * @param {string} groupName - name of onboarding group
  ###
  getItemsToRun: (groupName) ->

    groupSlug = @createGroupSlug groupName
    result    = @appStorage.getValue groupSlug

    return result  if result instanceof Array

  ###*
   * Updates in appStorage a list of onboarding item slugs which are left to run
   * for onboarding group
  ###
  updateItemsToRun: (groupName, itemSlugs, callback) ->

    groupSlug = @createGroupSlug groupName
    @appStorage.setValue groupSlug, itemSlugs, callback


  isPreviewMode: -> return checkFlag 'super-admin'