globals = require 'globals'
whoami = require './whoami'
isLoggedIn = require './isLoggedIn'
gaEvent = require './gaEvent'

# Access control wrapper around mixpanel object.
module.exports = exports = (args...) ->

  return  unless analytics and globals.config.logToExternal

  # We decided to move to segment.io which multiplexes to many
  # services. This is still named mixpanel for legacy reasons. - SA
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
          "$id"          : _id
          "$username"    : nickname
          "$first_name"  : firstName
          "$last_name"   : lastName
          "$created"     : meta?.createdAt
          "$email"       : email
          subscription   : currentSub
          lastLoginDate  : lastLoginDate
          status         : status
          emailFrequency :
            marketing    : emailFrequency?.marketing
            global       : emailFrequency?.global
          foreignAuth    : providers      if Object.keys(providers).length > 0
          sshKeysCount   : sshKeys.length if sshKeys?.length > 0

        analytics.identify nickname, args

  kd.getSingleton('mainController').on "AccountChanged", (account) ->
    return  unless isLoggedIn() and account and analytics

    kd.utils.defer -> identifyUser account


  if args.length < 2
    args.push {}

  me = whoami()
  return  unless me.profile

  gaEvent args[0]

  args[1]["username"] = me.profile.nickname

  analytics.track args...

exports.alias = (args...)->
  return  unless analytics and globals.config.logToExternal
  analytics.alias args...
