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


  openTeamSettings: (browser) ->

    teamsHelpers.loginTeam(browser)
    teamsHelpers.clickTeamSettings(browser)

    browser.end()


  checkTeamSettings: (browser) ->

    user = teamsHelpers.loginTeam(browser)
    teamsHelpers.clickTeamSettings(browser)

    teamSettingsSelector = '.AppModal--admin-tabs .general-settings'

    browser
      .waitForElementVisible  teamSettingsSelector, 20000
      .waitForElementVisible  'input[name=title]', 20000
      .assert.valueContains   'input[name=title]', user.teamSlug
      .waitForElementVisible  'input[name=url]', 20000
      .assert.valueContains   'input[name=url]', user.teamSlug
      .waitForElementVisible  '.avatar-upload .avatar', 20000
      .end()


  stacks: (browser) ->

    teamsHelpers.loginTeam(browser)
    teamsHelpers.createStack(browser)
    browser.end()


  stacksSkipSetupGuide: (browser) ->

    teamsHelpers.loginTeam(browser)
    teamsHelpers.createStack(browser, yes)
    browser.end()


  checkNotReadyAndPrivateIconsDisplayedForStacks: (browser) ->

    teamsHelpers.loginTeam(browser)
    teamsHelpers.createStack(browser, yes)
    teamsHelpers.checkIconsStacks(browser)
    browser.end()


  enableApiAccess: (browser) ->

    teamsHelpers.loginTeam(browser)
    teamsHelpers.clickTeamSettings(browser)
    teamsHelpers.enableAndDisableApiAccess(browser, yes, yes)
    browser.end()


  createAndDeleteApiToken: (browser) ->

    teamsHelpers.loginTeam(browser)
    teamsHelpers.clickTeamSettings(browser)
    teamsHelpers.enableAndDisableApiAccess(browser, yes)
    teamsHelpers.addNewApiToken(browser)
    browser.end()


  editStackName: (browser) ->

    teamsHelpers.loginTeam(browser)
    teamsHelpers.createStack(browser, yes)
    teamsHelpers.checkIconsStacks(browser, no)
    teamsHelpers.editStackName(browser)
    browser.end()
