utils        = require '../utils/utils.js'
helpers      = require '../helpers/helpers.js'
teamsHelpers = require '../helpers/teamshelpers.js'
user         = utils.getUser()
createLink   = "#{helpers.getUrl()}/Teams/Create"
inviteLink   = "#{helpers.getUrl()}/Teams/Create?email=#{user.email}"


module.exports =

  # Team Creation
  createTeamWithInvalidEmail: (browser) ->
    teamsHelpers.createTeam(browser, user, '', 'InvalidEmail')

  createTeamWithInvalidTeamUrl: (browser) ->
    teamsHelpers.createTeam(browser, user, '' , 'InvalidTeamUrl')

  createTeamWithAlreadyUsedTeamUrl: (browser) ->
    teamsHelpers.createTeam(browser, user, '' , 'AlreadyUsedTeamUrl')

  # Create Account Steps in Team Creation
  createAccountWithInvalidUserName: (browser) ->
    user         = utils.getUser(yes)
    teamsHelpers.createTeam(browser, user, '' , 'InvalidUserName')

  createAccountWithSameDomainAndUserName: (browser) ->
    user         = utils.getUser(yes)
    teamsHelpers.createTeam(browser, user, '' , 'SameDomainAndUserName')

  createAccountWithShortPassword: (browser) ->
    user = utils.getUser(yes)
    teamsHelpers.createTeam(browser, user, '' , 'ShortPassword')

  createAccountAlreadyRegisteredUserName: (browser) ->
    teamsHelpers.createTeam(browser, user, inviteLink)
    teamsHelpers.createTeam(browser, user, createLink, 'AlreadyRegisteredUserName')

  signInWithNotAllowedEmail: (browser) ->
    teamsHelpers.loginTeam(browser, user, yes , 'NotAllowedEmail')

  signInWithInvalidUsername: (browser) ->
    teamsHelpers.loginTeam(browser, user, yes, 'InvalidUserName')

  signInWithInvalidPassword: (browser) ->
    teamsHelpers.loginTeam(browser, user, yes, 'InvalidPassword')

  loginTeam: (browser) ->
    teamsHelpers.loginTeam(browser, user, no)

  after: (browser) ->
    browser.end()
