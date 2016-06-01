utils          = require '../utils/utils.js'
teamsHelpers   = require '../helpers/teamshelpers.js'
welcomehelper  = require '../helpers/welcomehelper.js'

module.exports =

  before: (browser, done) ->
    targetUser1 = utils.getUser no, 1
    targetUser1.role = 'member'
    users = targetUser1
    teamsHelpers.inviteAndJoinWithUsers browser, [users], (result) ->
      done()


  dashboard: (browser) ->
    welcomehelper.dashboardScreenAdmin browser, ->
      welcomehelper.testTeamBillingScreen browser, ->
        teamsHelpers.logoutTeam browser, ->
          welcomehelper.dashboardScreenMember browser        

  
  after: (browser) ->
    browser.end()

