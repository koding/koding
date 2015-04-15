kookies = require 'kookies'
remote = require('../remote').getInstance()
isLoggedIn = require '../util/isLoggedIn'
kd = require 'kd'
whoami = require 'app/util/whoami'
KDController = kd.Controller
OnboardingViewController = require './onboardingviewcontroller'


module.exports = class OnboardingController extends KDController

  constructor: (options = {}, data) ->

    super options, data

    @onboardings   = {}
    mainController = kd.getSingleton "mainController"

    if isLoggedIn() then @fetchItems()
    else
      mainController.on "accountChanged.to.loggedIn", @bound "fetchItems"


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

    @on "OnboardingRequested", (name) =>
      @runItems name


  runItems: (groupName) ->

    onboarding = @onboardings[groupName]
    return  unless onboarding
    return  unless onboarding.partial.items?.length

    slug      = kd.utils.slugify kd.utils.curry 'onboarding', groupName
    isShown   = @appStorage.getValue slug
    isOldUser = new Date(onboarding.createdAt) > @registrationDate

    return  if (isShown or isOldUser) and not @isPreviewMode

    kd.utils.wait 2000, =>
      new OnboardingViewController { groupName, slug, delegate: this }, onboarding.partial
