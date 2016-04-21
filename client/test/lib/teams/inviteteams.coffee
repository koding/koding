utils        = require '../utils/utils.js'
helpers      = require '../helpers/helpers.js'
teamsHelpers = require '../helpers/teamshelpers.js'


module.exports =

  inviteUser: (browser) ->

    teamsHelpers.loginTeam(browser)
    teamsHelpers.clickTeamSettings(browser)
    teamsHelpers.openInvitationsTab(browser)
    teamsHelpers.inviteUser(browser)
    browser.end()


  resendInvitation: (browser) ->

    teamsHelpers.loginTeam(browser)
    teamsHelpers.clickTeamSettings(browser)
    teamsHelpers.openInvitationsTab(browser)
    email = teamsHelpers.inviteUser(browser)
    browser.pause 5000 # Wait for notification remove
    teamsHelpers.invitationAction(browser, email)
    browser.end()


  revokeInvitation: (browser) ->

    teamsHelpers.loginTeam(browser)
    teamsHelpers.clickTeamSettings(browser)
    teamsHelpers.openInvitationsTab(browser)
    email = teamsHelpers.inviteUser(browser)
    browser.pause 5000 # Wait for notification remove
    teamsHelpers.invitationAction(browser, email, yes)
    browser.end()


  searchPendingInvitation: (browser) ->

    teamsHelpers.loginTeam(browser)
    teamsHelpers.clickTeamSettings(browser)
    teamsHelpers.openInvitationsTab(browser)
    teamsHelpers.inviteUser(browser, yes)
    browser.pause 5000 # Wait for notification
    email2 = teamsHelpers.inviteUser(browser, yes)
    teamsHelpers.clickPendingInvitations(browser, no)
    browser.pause 5000 # Wait for notification remove
    teamsHelpers.searchPendingInvitation(browser, email2)
    browser.end()


  inviteUserAndJoinTeam: (browser) ->

    targetUser = utils.getUser yes, 1
    teamsHelpers.loginTeam(browser)
    teamsHelpers.clickTeamSettings(browser)
    teamsHelpers.openInvitationsTab(browser)
    targetUser.email = teamsHelpers.inviteUser(browser)

    teamsHelpers.getInvitationUrl browser, targetUser.email, (url) ->
      teamsHelpers.closeTeamSettingsModal(browser)
      teamsHelpers.logoutTeam(browser)
      browser.url url
      browser.pause 2000
      teamsHelpers.checkForgotPassword(browser)
      teamsHelpers.fillJoinForm(browser, targetUser)
      browser.end()
