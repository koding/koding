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

  F1Key = 112

  constructor: (options = {}, data) ->

    super options, data

    @onboardings   = {}
    @isRunning     = no
    mainController = kd.getSingleton "mainController"

    if isLoggedIn() then @fetchItems()
    else
      mainController.on "accountChanged.to.loggedIn", @bound "fetchItems"

    $(document).on "keydown", @bound 'handleF1'


  fetchItems: ->

    account           = whoami()
    @registrationDate = new Date(account.meta.createdAt)
    @appStorage       = kd.getSingleton("appStorageController").storage "OnboardingStatus", "1.0.0"
    @isPreviewMode    = kookies.get("custom-partials-preview-mode") is "true"
    query             = partialType : "ONBOARDING"

    if @isPreviewMode
      query["isPreview"] = yes
    else
      query["isActive"]  = yes

    remote.api.JCustomPartials.some query, {}, (err, onboardings) =>
      return  if err

      for data in onboardings when data.partial
        @onboardings[data.name] = data

      @appStorage.fetchStorage @bound "bindOnboardingEvents"


  bindOnboardingEvents: ->

    @on "OnboardingShown", (slug) =>
      @appStorage.setValue slug, yes
      @isRunning = no

    @on "OnboardingRequested", (name) =>
      @runItems name


  runItems: (groupName, delay = 2000) ->

    onboarding = @onboardings[groupName]
    return  unless onboarding
    return  unless onboarding.partial.items?.length

    slug      = @createSlug groupName
    isShown   = @appStorage.getValue slug
    isOldUser = new Date(onboarding.createdAt) > @registrationDate

    return  if (isShown or isOldUser) and not @isPreviewMode

    @isRunning = yes
    kd.utils.wait delay, =>
      new OnboardingViewController { groupName, slug, delegate: this }, onboarding.partial


  handleF1: (event) ->

    return  unless event.which is F1Key

    event.preventDefault()
    event.stopPropagation()

    return  if @isRunning

    appManager   = kd.getSingleton "appManager"
    appName      = appManager.frontApp?.options.name

    if appName is "IDE"
      mountedMachine = appManager.frontApp?.mountedMachine
      if mountedMachine?.status.state is Machine.State.Running
        groupName = "IDE"

    return  unless groupName

    slug = @createSlug groupName
    @appStorage.setValue slug, no
    @runItems groupName, 0


  createSlug: (groupName) ->

    return kd.utils.slugify kd.utils.curry 'onboarding', groupName