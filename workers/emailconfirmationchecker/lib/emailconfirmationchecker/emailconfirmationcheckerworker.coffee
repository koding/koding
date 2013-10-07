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
      "registeredAt": {
        $lte: lessThanFilterDate
        $gt: greaterThanFilterDate
      }
    }

    JUser.each userSelector, {}, (err, user)=>
      if err then return console.error err
      return  if not user
      {username} = user
      accountSelector = {
        type   : {$ne : "unregistered" }
        status : {$ne : 'tobedeleted'  }
        "profile.nickname": username
      }

      JAccount.one accountSelector, (err, account)=>
        return console.error err  if err
        return  unless account
        account.sendNotification "EmailShouldBeConfirmed", account
        console.log "#{username} did not confirmed password, will be logged out"
        # We decided not to remove sessions
        # JSession.remove {"username": username}, (err)=>
        #   return  console.error err  if err

  init: ->
    guestCleanerCron = new CronJob @options.cronSchedule, @logoutUnregisteredUsers
    guestCleanerCron.start()
