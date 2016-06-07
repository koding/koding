utils        = require '../utils/utils.js'
helpers      = require '../helpers/helpers.js'
teamsHelpers = require '../helpers/teamshelpers.js'


module.exports =


  createTeam: (browser) ->

    user       = utils.getUser(yes)
    inviteLink = "#{helpers.getUrl()}/Teams/Create?email=#{user.email}"

    teamsHelpers.createTeam(browser, user, inviteLink)
    browser.end()


  createTeamWithInvalidCredentials: (browser) ->

    user       = utils.getUser(yes)
    inviteLink = "#{helpers.getUrl()}/Teams/Create?email=#{user.email}"

    teamsHelpers.createTeam(browser, user, inviteLink, yes)
    browser.end()


  useAlreadyRegisteredUserName: (browser) ->

    user        = utils.getUser(yes)
    createLink  = "#{helpers.getUrl()}/Teams/Create"
    inviteLink  = "#{helpers.getUrl()}/Teams/Create?email=#{user.email}"

    teamsHelpers.createTeam(browser, user, inviteLink)
    teamsHelpers.createTeam(browser, user, createLink)
    browser.end()


  loginTeam: (browser) ->

    teamsHelpers.loginTeam(browser)
    browser.end()
