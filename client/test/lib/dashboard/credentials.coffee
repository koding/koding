teamsHelpers      = require '../helpers/teamshelpers.js'
helpers           = require '../helpers/helpers.js'
utils             = require '../utils/utils.js'
async             = require 'async'
credentialshelper = require '../helpers/credentialshelpers.js'

module.exports =

  before: (browser, done) ->

    ###
    * we are creating users list here to send invitation and join to team
    * so we will be able to run our test for different kind of member role
    ###
    targetUser1 = utils.getUser no, 1
    targetUser1.role = 'member'

    users = [
      targetUser1
    ]

    queue = [
      (next) ->
        teamsHelpers.inviteAndJoinWithUsers browser, users, (result) ->
          next null, result
      (next) ->
        teamsHelpers.createCredential browser, 'aws', 'aws1', yes, (res) ->
          next null, res
      (next) ->
        teamsHelpers.createCredential browser, 'aws', 'aws2', yes, (res) ->
          next null, res
    ]

    async.series queue, (err, result) ->
      done()  unless err


  credentials: (browser) ->
    queue = [
      (next) ->
        credentialshelper.seeCredentials browser, (result) ->
          next null, result
      (next) ->
        credentialshelper.seeDetailsCredentials browser, (result) ->
          next null, result
      (next) ->
        credentialshelper.removeSingleCredential browser, (result) ->
          next null, result
    ]

    async.series queue

  after: (browser) ->
    browser.end()
