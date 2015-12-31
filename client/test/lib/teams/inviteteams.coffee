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
    teamsHelpers.invitationAction(browser, email)
    browser.end()


  revokeInvitation: (browser) ->

    user = teamsHelpers.loginTeam(browser)
    teamsHelpers.clickTeamSettings(browser)
    teamsHelpers.openInvitationsTab(browser)
    email = teamsHelpers.inviteUser(browser)
    teamsHelpers.invitationAction(browser, email, yes)
    browser.end()
