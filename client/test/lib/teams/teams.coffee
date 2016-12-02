utils = require '../utils/utils.js'
helpers = require '../helpers/helpers.js'
teamsHelpers = require '../helpers/teamshelpers.js'
user = utils.getUser()
createLink = "#{helpers.getUrl()}/Teams/Create"
inviteLink = "#{helpers.getUrl()}/Teams/Create?email=#{user.email}"
linkSelector = '.content-page.Team section p'
resetPasswordSelector = '.TeamsModal-button'

module.exports =

  # # Team Creation
  createTeamWithInvalidEmail: (browser) ->
    teamsHelpers.createTeam(browser, user, '', 'InvalidEmail')

  createTeamWithInvalidTeamUrl: (browser) ->
    teamsHelpers.createTeam(browser, user, '' , 'InvalidTeamUrl')

  createTeamWithEmptyTeamUrl: (browser) ->
    teamsHelpers.createTeam(browser, user, '' , 'EmptyTeamUrl')

  createTeamWithUpperCaseTeamUrl: (browser) ->
    teamsHelpers.createTeam(browser, user, '' , 'UpperCaseTeamUrl')

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

  # createAccountAlreadyRegisteredUserName: (browser) ->
  #   url = helpers.getUrl()
  #   teamsHelpers.createTeam(browser, user, inviteLink)
  #   teamsHelpers.createTeam(browser, user, createLink, 'AlreadyRegisteredUserName')
  #   teamsHelpers.logoutTeamfromUrl browser, (result) ->
  #     browser.url url
  #     browser.waitForElementVisible '.content-page.Team section a.previous-team', 40000

  signInWithNotAllowedEmail: (browser) ->
    teamsHelpers.loginTeam browser, user, yes , 'NotAllowedEmail', ->
      browser.end()


  signInWithInvalidUsername: (browser) ->
    teamsHelpers.loginTeam browser, user, yes, 'InvalidUserName', ->
      browser.end()


  signInWithInvalidPassword: (browser) ->
    teamsHelpers.loginTeam browser, user, yes, 'InvalidPassword', ->
      browser.end()


  loginTeam: (browser) ->
    teamsHelpers.loginTeam browser, user, no, ->
      browser.end()


  checkAllLinkInTheFooter: (browser) ->
    url = helpers.getUrl(yes)
    browser.maximizeWindow()
    browser.url url
    browser.element 'css selector', linkSelector + ' p:nth-of-type(1)', (result) ->
      if result.status is 0
        browser
          .waitForElementVisible linkSelector + ' p:nth-of-type(1)', 20000
          .click linkSelector + ' p:nth-of-type(1) a'
          .waitForElementVisible '.TeamsModal.TeamsModal--login', 20000
          .click linkSelector + ':nth-of-type(2) a'
          .waitForElementVisible '.content-page.Team .TeamsModal--create', 20000
          .url url
          .click linkSelector + ':nth-of-type(3) a'
          .waitForElementVisible resetPasswordSelector, 20000
          .assert.containsText resetPasswordSelector, 'RECOVER PASSWORD'


  after: (browser) ->
    browser.end()
