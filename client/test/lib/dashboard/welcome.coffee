utils          = require '../utils/utils.js'
teamsHelpers   = require '../helpers/teamshelpers.js'
welcomehelper  = require '../helpers/welcomehelper.js'
async = require 'async'

module.exports =

  before: (browser, done) ->
    targetUser1 = utils.getUser no, 1
    targetUser1.role = 'member'
    users = targetUser1
    teamsHelpers.inviteAndJoinWithUsers browser, [users], (result) ->
      done()


  dashboard: (browser, done) ->
    queue = [
      (next) ->
        welcomehelper.dashboardScreenAdmin browser, (result) ->
          next null, result
      (next) ->
        welcomehelper.testTeamBillingScreen browser, (result) ->
          next null, result
      (next) ->
        teamsHelpers.logoutTeam browser, (result) ->
          next null, result
      (next) ->
        welcomehelper.dashboardScreenMember browser, (result) ->
          next null, result
    ]

    async.series queue, (err, result) ->
      if err
        console.log(err)

  after: (browser) ->
    browser.end()

