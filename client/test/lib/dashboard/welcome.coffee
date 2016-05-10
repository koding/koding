utils   = require '../utils/utils.js'
helpers = require '../helpers/helpers.js'
teamsHelpers = require '../helpers/teamshelpers.js'
myteamHelpers = require '../helpers/myteamhelpers.js'
myTeamLink = "#{helpers.getUrl(yes)}/Home/my-team"
homehelpers = require '../helpers/welcomehelpers.js'

module.exports =
 
  # checkAdminStackView: (browser) ->
  #   teamsHelpers.loginTeam(browser)
  #   homehelpers.verifyStackView(browser)
   
  # checkAdminTeamInvite: (browser) ->
  #   teamsHelpers.loginTeam(browser)
  #   homehelpers.verifyTeamView(browser)

  checkUserKDInstallScreen: (browser) ->
    teamsHelpers.loginTeam(browser)
    targetUser = utils.getUser(yes, 1);
    browser.url myTeamLink
    browser.pause 3000   
    teamsHelpers.getInvitationUrl browser, targetUser.email, (url) ->
      browser.url url, ->
        teamsHelpers.fillJoinForm browser, targetUser
    
    browser.end() 
    # targetUser.email = myteamHelpers.inviteUser browser, 'member'
    
    # teamsHelpers.getInvitationUrl browser, targetUser.email, (url) ->
    #   browser.url url, ->
    #     teamsHelpers.fillJoinForm browser, targetUser
     # homehelpers.verifyKDInstallView(browser, user)

  # checkUserStackPendingScreen: (browser) ->
  #   teamsHelpers.loginTeam(browser)
  #   user = utils.getUser(no, 5);
  #   browser.url myTeamLink      
  #   myteamHelpers.inviteTheUser browser, user, 'member'
  #   homehelpers.verifyPendingStackView(browser, user)

  # checkUserPrivateStack: (browser) ->
  #   teamsHelpers.loginTeam(browser)
  #   user = utils.getUser(no, 6);
  #   browser.url myTeamLink
  #   myteamHelpers.inviteTheUser browser, user, 'member'
  #   homehelpers.verifyStackView(browser, user)


    
    
