teamsHelpers   = require '../helpers/teamshelpers.js'
helpers        = require '../helpers/helpers.js'
utils          = require '../utils/utils.js'
async          = require 'async'
stackSelector  = null
stackshelpers  = require '../helpers/stackshelpers.js'

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
      # (next) ->
      #   teamsHelpers.createCredential browser, 'aws', 'test credential', no, (res) ->
      #     next null, res
      # (next) ->
      #   teamsHelpers.createStack browser, (res) ->
      #     next null, res

      # (next) ->
      #   teamsHelpers.createDefaultStackTemplate browser, (res) ->
      #     # remove main url from result
      #     # to get '/Stack-Editor/machineId'
      #     res = res.substring helpers.getUrl(yes).length
      #     stackSelector = res
      #     next null, res
    ]

    async.series queue, (err, result) ->
      done()  unless err

  stacks: (browser) ->
    queue = [
      # (next) ->
      #   stackshelpers.clickNewStackButton browser, (result) ->
      #     next null, result
      # (next) ->
      #   stackshelpers.seeTeamStackTemplates browser, (result) ->
      #     next null, result
      # (next) ->
      #   stackshelpers.seeDraftStackTemplates browser, (result) ->
      #     next null, result
      # (next) ->
      #   stackshelpers.editStackTemplates browser, (result) ->
      #     next null, result
      # (next) ->
      #   stackshelpers.deleteCredentialInUse browser, (result) ->
      #     next null, result
      # (next) ->
      #   stackshelpers.deleteStackTemplatesInUse browser, (result) ->
      #     next null, result
      # (next) ->
      #   stackshelpers.deleteStackTemplates browser, (result) ->
      #     next null, result
      # (next) ->
      #   teamsHelpers.logoutTeam browser, (result) ->
      #     next null, result
      # (next) ->
      #   stackshelpers.createPrivateStackAsMember browser, (result) ->
      #     next null, result

      # (next) ->
      #   stackshelpers.checkAndDestroyVm browser, (result) ->
      #     next null, result

      (next) ->
        stackshelpers.destroy browser, (result) ->
          next null, result
    ]

    async.series queue

  # after: (browser) ->
  #   browser.end()
