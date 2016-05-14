utils   = require '../utils/utils.js'
helpers = require '../helpers/helpers.js'
teamsHelpers = require '../helpers/teamshelpers.js'
welcomehelpers = require '../helpers/welcomehelpers.js'

module.exports =
  before: (browser, done) ->
    targetUser1 = utils.getUser no, 1
    targetUser1.role = 'member'
    users = targetUser1
    teamsHelpers.inviteAndJoinWithUsers browser, [users], (result) ->
      done()
  
  checkDashboardbyAdmin: (browser) ->
    welcomehelpers.seeStackView(browser)
    browser.url  "#{helpers.getUrl(yes)}/Home/Welcome"
    welcomehelpers.seeTeamView(browser)
    browser.url  "#{helpers.getUrl(yes)}/Home/Welcome"
    browser.pause 3000
    welcomehelpers.seeKDInstall(browser)
    browser.end()

  checkDashboardViewbyMember: (browser) ->
    targetUser1 = utils.getUser no, 1
    teamsHelpers.logoutTeam browser, (res) ->
      teamsHelpers.loginToTeam browser, targetUser1 , no, ->
      browser.pause 3000
      welcomehelpers.seePendingStackView browser
      welcomehelpers.seePersonalStackView(browser)    
      browser.url  "#{helpers.getUrl(yes)}/Home/Welcome"
      browser.pause 3000
      welcomehelpers.seeKDInstall(browser)
      browser.end()
