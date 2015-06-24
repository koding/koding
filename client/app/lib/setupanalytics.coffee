kd          = require 'kd'
globals     = require 'globals'
isLoggedIn = require './util/isLoggedIn'

setupIdentify = ->

  kd.getSingleton('mainController').on 'AccountChanged', (account) ->
    return  unless isLoggedIn() and account
    kd.utils.defer -> identifyUser account

identifyUser = (account)->

  {_id, meta, profile} = account
  return  unless profile

  remote = require('app/remote').getInstance()
  remote.api.JUser.fetchUser (err, user)->
    return  if err or not user

    {firstName, lastName, nickname} = profile
    {email, lastLoginDate, status, emailFrequency, foreignAuth, sshKeys} = user

    # only care about existence of 3rd party auth, not the values
    providers = {}
    if foreignAuth
      for own provider, providerInfo of foreignAuth
        # check if values isn't empty object
        providers[provider] = yes  if Object.keys(providerInfo).length > 0

    kd.singletons.paymentController.subscriptions (err, currentSub) ->
      plan = "error fetching plan" if err
      args =
        firstName      : firstName
        lastName       : lastName
        createdAt      : meta?.createdAt
        email          : email
        subscription   : currentSub
        lastLoginDate  : lastLoginDate
        status         : status
        emailFrequency :
          marketing    : emailFrequency?.marketing
          global       : emailFrequency?.global
        foreignAuth    : providers      if Object.keys(providers).length > 0
        sshKeysCount   : sshKeys.length if sshKeys?.length > 0
        userAgent      : navigator.userAgent
        env            : globals.config.environment

      analytics?.identify nickname, args

setupPageAnalyticsEvent = ->

  kd.singletons.router.on 'RouteInfoHandled', (args) ->
    {path} = args
    return  unless path

    title = getFirstPartOfpath(path)
    analytics?.page(title, {title:document.title, path})

getFirstPartOfpath = (path) -> return path.split("/")[1] or path

setupRollbar = ->

  Rollbar?.configure
    payload: client: javascript:
      source_map_enabled:    true
      guess_uncaught_frames: true
      code_version:          globals.config.version

module.exports = ->

  setupIdentify()
  setupPageAnalyticsEvent()
  setupRollbar()
