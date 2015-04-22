kookies = require 'kookies'
remote = require('../remote').getInstance()
isLoggedIn = require '../util/isLoggedIn'
$ = require 'jquery'
kd = require 'kd'
whoami = require 'app/util/whoami'
KDController = kd.Controller
OnboardingViewController = require './onboardingviewcontroller'
Machine = require 'app/providers/machine'


module.exports = class OnboardingController extends KDController

  F1_KEY = 112

  constructor: (options = {}, data) ->

    super options, data

    @onboardings   = {}
    @previewModes  = {}
    @isRunning     = no
    { mainController, windowController } = kd.singletons

    if isLoggedIn() then @fetchItems()
    else
      mainController.on 'accountChanged.to.loggedIn', @bound 'fetchItems'

    windowController.on 'keydown', @bound 'handleF1'


  fetchItems: ->

    account           = whoami()
    @registrationDate = new Date(account.meta.createdAt)
    @appStorage       = kd.getSingleton('appStorageController').storage 'OnboardingStatus', '1.0.0'
    isPreviewMode     = kookies.get('custom-partials-preview-mode') is 'true'
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

      @appStorage.fetchStorage()


  runOnboarding: (groupName, delay = 2000, forceRun = no) ->

    onboarding = @onboardings[groupName]
    return  unless onboarding
    return  unless onboarding.partial.items?.length

    forceRun  = @previewModes[groupName]  unless forceRun

    slug      = @createSlug groupName
    isShown   = @appStorage.getValue slug
    isOldUser = new Date(onboarding.createdAt) > @registrationDate

    # reset preview mode for onboarding group to avoid onboarding preview being annoying for admin
    # if admin wants to see onboarding once again, they just need to refresh the page
    @previewModes[groupName] = no

    return  if (isShown or isOldUser) and not forceRun

    @isRunning = yes
    kd.utils.wait delay, =>
      viewController = new OnboardingViewController { groupName, slug }, onboarding.partial
      viewController.on 'OnboardingEnded', @bound 'handleOnboardingEnded'


  handleOnboardingEnded: (slug) ->

    @appStorage.setValue slug, yes
    @isRunning = no


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


  createSlug: (groupName) ->

    return kd.utils.slugify kd.utils.curry 'onboarding', groupName