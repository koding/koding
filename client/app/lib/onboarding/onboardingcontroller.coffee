kookies = require 'kookies'
remote = require('../remote').getInstance()
isLoggedIn = require '../util/isLoggedIn'
$ = require 'jquery'
kd = require 'kd'
whoami = require 'app/util/whoami'
checkFlag = require 'app/util/checkFlag'
KDController = kd.Controller
OnboardingViewController = require './onboardingviewcontroller'
OnboardingEvent = require 'app/onboarding/onboardingevent'
KDModalView = kd.ModalView


module.exports = class OnboardingController extends KDController

  IS_SHOWN         = 'is_shown'
  NEED_TO_BE_SHOWN = 'need_to_be_shown'


  ###*
   * A controller that manages onboardings for the current user
   * It fetchs onboardings from DB and starts them when it's necessary
  ###
  constructor: (options = {}, data) ->

    super options, data

    @onboardings   = {}
    @pendingQueue  = []
    @isReady       = no
    @isRunning     = no
    { mainController, windowController } = kd.singletons

    if isLoggedIn() then @fetchItems()
    else
      mainController.on 'accountChanged.to.loggedIn', @bound 'fetchItems'


  ###*
   * Fetches onboardings from DB
   * Preview mode is always enabled for super admin, so super admin always gets onboardings on preview
   * Other users receive published onboardings
  ###
  fetchItems: ->

    account           = whoami()
    @registrationDate = new Date(account.meta.createdAt)
    @appStorage       = kd.getSingleton('appStorageController').storage 'OnboardingStatus', '1.0.0'
    query             = partialType : 'ONBOARDING'

    if @isPreviewMode()
      query['isPreview'] = yes
    else
      query['isActive']  = yes

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

    @isReady = yes
    @resetOnboardings()  if @isPreviewMode()
    @runOnboarding.apply this, args for args in @pendingQueue


  ###*
   * Runs onboarding group by name
   * Onboarding can be run if it was not shown for the current user yet
   * and user was registered after onboarding had been published
   * Also, it can be shown if it was requested to show it again
   * If controller is not ready yet, onboarding request is added to pending queue
   * 
   * @param {string} groupName - name of onboarding group
   * @param {number} delay     - time to wait before running onboarding, by default it's 2s
  ###
  runOnboarding: (groupName, delay = 2000) ->

    return @pendingQueue.push Array::slice.call(arguments)  unless @isReady

    onboarding = @onboardings[groupName]
    return  unless onboarding
    return  unless onboarding.partial.items?.length

    slug               = @createSlug groupName
    forceRun           = @appStorage.getValue(slug) is NEED_TO_BE_SHOWN

    isAvailableForUser = if onboarding.publishedAt
    then new Date(onboarding.publishedAt) < @registrationDate
    else no
    isAvailableForUser = not(@appStorage.getValue slug)  if isAvailableForUser

    return  unless (isAvailableForUser or forceRun)

    @isRunning = yes
    kd.utils.wait delay, =>
      viewController = new OnboardingViewController { groupName, slug }, onboarding.partial
      viewController.on 'OnboardingEnded', @bound 'handleOnboardingEnded'


  ###*
   * For all onboardings it saves a value in DB that requests to show onboarding again
   *
   * @param {bool} showNotification - indicates if notification modal should appear after resetting onboardings
  ###
  resetOnboardings: (showNotification) ->

    for event of OnboardingEvent
      slug = @createSlug event
      @appStorage.setValue slug, NEED_TO_BE_SHOWN

    if showNotification
      modal = new KDModalView
        title          : 'Onboarding has been reset'
        content        : '''
          <p>
            To start the onboarding process, please reload this page
          </p>
        '''
        overlay        : yes
        buttons        :
          reload       :
            cssClass   : 'solid green medium'
            title      : 'Reload page'
            callback   : ->
              modal.destroy()
              global.location.reload yes


  ###*
   * Method is executed once onboarding is ended
   * It saves a value in DB that shows that onboarding was shown for the user
   * 
   * @param {string} slug - onboarding slug
  ###
  handleOnboardingEnded: (slug) ->

    @appStorage.setValue slug, IS_SHOWN
    @isRunning = no


  ###*
   * Creates onboarding slug in correct format
   * 
   * @param {string} groupName - name of onboarding group
  ###
  createSlug: (groupName) ->

    return kd.utils.slugify kd.utils.curry 'onboarding', groupName


  isPreviewMode: -> return checkFlag 'super-admin'