utils        = require '../utils/utils.js'
helpers      = require '../helpers/helpers.js'
teamsHelpers = require '../helpers/teamshelpers.js'
user         = utils.getUser()
createLink   = "#{helpers.getUrl()}/Teams/Create"
inviteLink   = "#{helpers.getUrl()}/Teams/Create?email=#{user.email}"


module.exports =

  #Team Creation
  createTeamWithInvalidEmail: (browser) ->
    teamsHelpers.createTeam(browser, user, '', 'InvalidEmail')

  createTeamWithInvalidTeamUrl: (browser) ->
    teamsHelpers.createTeam(browser, user, '' , 'InvalidTeamUrl')

  createTeamWithAlreadyUsedTeamUrl: (browser) ->
    teamsHelpers.createTeam(browser, user, '' , 'AlreadyUsedTeamUrl')

  #Create Account Steps in Team Creation
  createAccountWithInvalidUserName: (browser) ->
    user         = utils.getUser(yes)
    teamsHelpers.createTeam(browser, user, '' , 'InvalidUserName')

  createAccountAlreadyRegisteredUserName: (browser) ->
    teamsHelpers.createTeam(browser, user, inviteLink)
    teamsHelpers.createTeam(browser, user, createLink, 'AlreadyRegisteredUserName')

  createAccountWithShortPassword: (browser) ->
    user = utils.getUser(yes)
    teamsHelpers.createTeam(browser, user, '' , 'ShortPassword')

  loginTeam: (browser) ->
    teamsHelpers.loginTeam(browser, user, yes)

  after: (browser) ->
    browser.end()
