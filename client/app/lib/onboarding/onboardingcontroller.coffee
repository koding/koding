kookies = require 'kookies'
remote = require('../remote').getInstance()
isLoggedIn = require '../util/isLoggedIn'
$ = require 'jquery'
kd = require 'kd'
whoami = require 'app/util/whoami'
checkFlag = require 'app/util/checkFlag'
KDController = kd.Controller
OnboardingViewController = require './onboardingviewcontroller'
Machine = require 'app/providers/machine'


module.exports = class OnboardingController extends KDController

  F1_KEY = 112

  ###*
   * A controller that manages onboardings for the current user
   * It fetchs onboardings from DB and starts them when it's necessary
  ###
  constructor: (options = {}, data) ->

    super options, data

    @onboardings   = {}
    @previewModes  = {}
    @pendingQueue  = []
    @isReady       = no
    @isRunning     = no
    { mainController, windowController } = kd.singletons

    if isLoggedIn() then @fetchItems()
    else
      mainController.on 'accountChanged.to.loggedIn', @bound 'fetchItems'

    windowController.on 'keydown', @bound 'handleF1'


  ###*
   * Fetches onboardings from DB
   * Preview mode is always enabled for super admin, so super admin always gets onboardings on preview
   * Other users get published onboardings
  ###
  fetchItems: ->

    account           = whoami()
    @registrationDate = new Date(account.meta.createdAt)
    @appStorage       = kd.getSingleton('appStorageController').storage 'OnboardingStatus', '1.0.0'
    isPreviewMode     = checkFlag 'super-admin'
    query             = partialType : 'ONBOARDING'

    if isPreviewMode
      query['isPreview'] = yes
    else
      query['isActive']  = yes

    remote.api.JCustomPartials.some query, {}, (err, onboardings) =>
      return kd.warn err  if err

      for data in onboardings when data.partial
        @onboardings[data.name]  = data
        @previewModes[data.name] = isPreviewMode

      @appStorage.fetchStorage @bound 'ready'


  ###*
   * It is executed once all data is loaded
   * It runs all onboardings which were requested while data was loading
   * and therefore were added to pending queue
  ###
  ready: ->

    @isReady = yes
    @runOnboarding.apply this, args for args in @pendingQueue


  ###*
   * Runs onboarding group by name
   * Onboarding can be run if it was not shown for the current user yet
   * and user was registered after onboarding had been published
   * If forceRun is yes, it skips all checks and run onboarding anyway
   * It's used for F1 mode and preview mode
   * If controller is not ready yet, onboarding request is added to pending queue
   * 
   * @param {string} groupName - name of onboarding group
   * @param {number} delay     - time to wait before running onboarding, by default it's 2s
   * @param {bool} forceRun    - if it's yes, skip all user checks and run onboarding anyway
  ###
  runOnboarding: (groupName, delay = 2000, forceRun = no) ->

    return @pendingQueue.push Array::slice.call(arguments)  unless @isReady

    onboarding = @onboardings[groupName]
    return  unless onboarding
    return  unless onboarding.partial.items?.length

    forceRun  = @previewModes[groupName]  unless forceRun
    slug      = @createSlug groupName

    isAvailableForUser = if onboarding.publishedAt
    then new Date(onboarding.publishedAt) < @registrationDate
    else no
    isAvailableForUser = not(@appStorage.getValue slug)  if isAvailableForUser

    # reset preview mode for onboarding group to avoid onboarding preview being annoying for admin
    # if admin wants to see onboarding once again, they just need to refresh the page
    @previewModes[groupName] = no

    return  unless (isAvailableForUser or forceRun)

    @isRunning = yes
    kd.utils.wait delay, =>
      viewController = new OnboardingViewController { groupName, slug }, onboarding.partial
      viewController.on 'OnboardingEnded', @bound 'handleOnboardingEnded'


  ###*
   * Method is executed once onboarding is ended
   * It saves a flag that onboarding was shown for the user to DB
   * 
   * @param {string} slug - onboarding slug
  ###
  handleOnboardingEnded: (slug) ->

    @appStorage.setValue slug, yes
    @isRunning = no


  ###*
   * Handles F1 button press and checks if it's possible to start onboarding
   * depending on the current context
   * If it's so, starts the first proper onboarding
   * 
   * @param {KeyboardEvent} event - keydown event
  ###
  handleF1: (event) ->

    return  unless event.which is F1_KEY

    event.preventDefault()
    event.stopPropagation()

    return  if @isRunning

    appManager   = kd.getSingleton 'appManager'
    appName      = appManager.frontApp?.options.name

    if appName is 'IDE'
      mountedMachine = appManager.frontApp?.mountedMachine
      if mountedMachine?.status.state is Machine.State.Running
        groupName = 'IDE'

    return  unless groupName

    @runOnboarding groupName, 0, yes


  ###*
   * Creates onboarding slug in correct format
   * 
   * @param {string} groupName - name of onboarding group
  ###
  createSlug: (groupName) ->

    return kd.utils.slugify kd.utils.curry 'onboarding', groupName