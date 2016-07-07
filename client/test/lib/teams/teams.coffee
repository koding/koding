utils        = require '../utils/utils.js'
helpers      = require '../helpers/helpers.js'
teamsHelpers = require '../helpers/teamshelpers.js'

module.exports =

  createTeamWithInvalidEmail: (browser) ->
    user       = utils.getUser(yes)
    teamsHelpers.createTeam(browser, user, '', 'InvalidEmail')

  createTeamWithInvalidTeamUrl: (browser) ->
    user       = utils.getUser(yes)
    teamsHelpers.createTeam(browser, user, '', 'InvalidTeamUrl')

  createTeamWithAlreadyUsedTeamUrl: (browser) ->
    user       = utils.getUser(yes)
    teamsHelpers.createTeam(browser, user,'', 'AlreadyUsedTeamUrl')

  createTeamWithInvalidUserName: (browser) ->
    user       = utils.getUser(yes)
    teamsHelpers.createTeam(browser, user,'', 'InvalidUserName')

  createAlreadyRegisteredUserName: (browser) ->
    user        = utils.getUser(yes)
    createLink  = "#{helpers.getUrl()}/Teams/Create"
    inviteLink  = "#{helpers.getUrl()}/Teams/Create?email=#{user.email}"

    teamsHelpers.createTeam(browser, user, inviteLink)
    teamsHelpers.createTeam(browser, user, createLink, 'AlreadyRegisteredUserName')

  loginTeam: (browser) ->

    teamsHelpers.loginTeam(browser)
    browser.end()

  after: (browser) ->
    browser.end()
