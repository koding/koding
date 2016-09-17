utils              = require '../utils/utils.js'
teamsHelpers       = require '../helpers/teamshelpers.js'
myaccounthelper  = require '../helpers/myaccounthelpers.js'
async = require 'async'

module.exports =

  before: (browser, done) ->
    targetUser1 = utils.getUser no, 1
    targetUser1.role = 'member'
    users = targetUser1
    teamsHelpers.inviteAndJoinWithUsers browser, [users], (result) ->
      done()


  myaccount: (browser) ->
    queue = [
      (next) ->
        myaccounthelper.updateFirstName browser, (result) ->
          next null, result
      (next) ->
        myaccounthelper.updateLastName browser, (result) ->
          next null, result
      (next) ->
        myaccounthelper.updateEmailWithInvalidPassword browser, (result) ->
          next null, result
      (next) ->
        myaccounthelper.updateEmailWithInvalidPin browser, (result) ->
          next null, result
      (next) ->
        myaccounthelper.updatePassword browser, (result) ->
          next null, result

    ]

    async.series queue

  after: (browser) ->
    browser.end()
