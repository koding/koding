utils = require '../utils/utils.js'
helpers = require '../helpers/helpers.js'
teamsHelpers = require '../helpers/teamshelpers.js'
utils = require '../utils/utils.js'
myteamhelpers = require '../helpers/myteamhelpers.js'
myTeamLink = "#{helpers.getUrl(yes)}/Home/my-team"

module.exports =

  sendInvites: (browser) ->

    user = teamsHelpers.loginTeam browser
    browser.url myTeamLink
    myteamhelpers.inviteUser browser
    browser.end()


  sendInvitesToAll: (browser) ->

    user = teamsHelpers.loginTeam browser
    browser.url myTeamLink
    myteamhelpers.inviteAll browser
    browser.end()

  checkUploadCSV: (browser) ->

    user = teamsHelpers.loginTeam browser
    browser.url myTeamLink
    myteamhelpers.uploadCSV browser
    browser.end()


  resendInvitation: (browser) ->

    user = teamsHelpers.loginTeam browser
    browser.url myTeamLink
    myteamhelpers.resendInvitation browser, 'member'
    browser.pause 5000
    myteamhelpers.resendInvitation browser, 'admin'
    browser.end()

  newInviteFromResendModal: (browser) ->

    user = teamsHelpers.loginTeam browser
    browser.url myTeamLink
    myteamhelpers.newInviteFromResendModal browser
    browser.end()