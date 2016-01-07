helpers  = require '../helpers/helpers.js'
utils    = require '../utils/utils.js'
teamsHelpers = require '../helpers/teamshelpers.js'


module.exports =

  inviteUser: (browser) ->

    user = teamsHelpers.loginTeam(browser)
    teamsHelpers.clickTeamSettings(browser)
    teamsHelpers.openInvitationsTab(browser)
    teamsHelpers.inviteUser(browser)
    browser.end()


  resendInvitation: (browser) ->

    user = teamsHelpers.loginTeam(browser)
    teamsHelpers.clickTeamSettings(browser)
    teamsHelpers.openInvitationsTab(browser)
    email = teamsHelpers.inviteUser(browser)
    browser.pause 5000 # Wait for notification remove
    teamsHelpers.invitationAction(browser, email)
    browser.end()


  revokeInvitation: (browser) ->

    user = teamsHelpers.loginTeam(browser)
    teamsHelpers.clickTeamSettings(browser)
    teamsHelpers.openInvitationsTab(browser)
    email = teamsHelpers.inviteUser(browser)
    browser.pause 5000 # Wait for notification remove
    teamsHelpers.invitationAction(browser, email, yes)
    browser.end()


  searchPendingInvitation: (browser) ->

    user = teamsHelpers.loginTeam(browser)
    teamsHelpers.clickTeamSettings(browser)
    teamsHelpers.openInvitationsTab(browser)
    email1 = teamsHelpers.inviteUser(browser, yes)
    email2 = teamsHelpers.inviteUser(browser, yes)
    email3 = teamsHelpers.inviteUser(browser, yes)
    teamsHelpers.clickPendingInvitations(browser, no)
    browser.pause 5000 # Wait for notification remove
    teamsHelpers.searchPendingInvitation(browser, email2)
    browser.end()


