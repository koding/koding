jraphical = require 'jraphical'
{CronJob} = require 'cron'

module.exports = class EmailConfirmationChecker
  constructor: (@bongo, @options = {}) ->

  logoutUnregisteredUsers: =>
    {JAccount, JUser, JSession} = @bongo.models

    usageLimitInMinutes = @options.usageLimitInMinutes or 60

    lessThanFilterDate = new Date(Date.now() - (1000 * 60 * usageLimitInMinutes))
    #greater than filter date is only 5 min before than the actual usage limit
    greaterThanFilterDate = new Date(Date.now() - (1000 * 60 * (usageLimitInMinutes + 5) ))

    userSelector = {
      "status": 'unconfirmed'
      "username": { $nin: @getInProgressUsers() }
      "registeredAt": {
        $lte: lessThanFilterDate
        $gt: greaterThanFilterDate
      }
    }

    JUser.one userSelector, (err, user)=>
      if err then return console.error err
      if not user or user.length < 1
        @clearInProgressUsers()
        return console.log "No unconfirmed user between last 60 and 65 min"

      {username} = user
      @addToInProgressUsers username
      JAccount.one { "profile.nickname": username }, (err, account)=>
        if err
          @removeFromInProgressUsers username
          return console.error err

        unless account
          console.log "account not found!"
          return @removeFromInProgressUsers username

        account.sendNotification "GuestTimePeriodHasEnded", account

        JSession.remove {"username": username}, (err)=>
          if err then return console.error err
          @removeFromInProgressUsers username


  inProgressUsers = {}
  addToInProgressUsers: (username)->
    inProgressUsers[username] = true

  removeFromInProgressUsers: (username)->
    delete inProgressUsers[username]

  clearInProgressUsers:->
    inProgressUsers = {}

  getInProgressUsers: ->
    Object.keys inProgressUsers

  init: ->
    guestCleanerCron = new CronJob @options.cronSchedule, @logoutUnregisteredUsers
    guestCleanerCron.start()
