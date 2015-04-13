kookies = require 'kookies'
remote = require('../remote').getInstance()
isLoggedIn = require '../util/isLoggedIn'
kd = require 'kd'
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

    @on "OnboardingShown", (slug) =>
      @appStorage.setValue slug, yes


  fetchItems: ->

    @appStorage = kd.getSingleton("appStorageController").storage "OnboardingStatus", "1.0.0"
    @hasCookie  = kookies.get("custom-partials-preview-mode") is "true"
    query       = partialType : "ONBOARDING"

    if @hasCookie
      query["isPreview"] = yes
    else
      query["isActive"]  = yes

    remote.api.JCustomPartials.some query, {}, (err, onboardings) =>
      for data in onboardings when data.partial
        appName = data.partial.app
        @onboardings[appName] ?= []
        @onboardings[appName].push data

      @appStorage.fetchStorage @bound "bindOnboardingEvents"


  bindOnboardingEvents: ->

    appManager = kd.getSingleton "appManager"
    appManager.on "AppCreated", @bound 'runItemsForApp'

    @runItemsForApp appManager.frontApp  if appManager.frontApp?


  runItemsForApp: (app) ->

    appName = app.getOptions().name
    return  unless @onboardings[appName]

    kd.utils.wait 3000, =>
      onboardings = @onboardings[appName]

      for item in onboardings
        slug    = kd.utils.slugify kd.utils.curry appName, item.name
        isShown = @appStorage.getValue slug

        if not isShown or @hasCookie
          onboarding = item
          break

      return unless onboarding?.partial.items?.length

      new OnboardingViewController { app, slug, delegate: this }, onboarding.partial
