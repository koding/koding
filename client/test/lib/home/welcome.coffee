utils   = require '../utils/utils.js'
helpers = require '../helpers/helpers.js'
teamsHelpers = require '../helpers/teamshelpers.js'
myteamHelpers = require '../helpers/myteamhelpers.js'
myTeamLink = "#{helpers.getUrl(yes)}/Home/my-team"
homehelpers = require '../helpers/homehelpers.js'

module.exports =
 
  checkAdminStackView: (browser) ->
    teamsHelpers.loginTeam(browser)
    user = utils.getUser(false, 4);
    browser.url myTeamLink
    myteamHelpers.inviteTheUser browser, user, 'admin'
    homehelpers.verifyStackView(browser, user)
   
  checkAdminTeamInvite: (browser) ->
    teamsHelpers.loginTeam(browser)
    user = utils.getUser(false, 5);
    browser.url myTeamLink
    myteamHelpers.inviteTheUser browser, user, 'admin'
    homehelpers.verifyTeamView(browser, user)


    
    
