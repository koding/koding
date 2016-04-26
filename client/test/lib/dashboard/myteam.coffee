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
