helpers  = require '../helpers/helpers.js'
utils    = require '../utils/utils.js'
teamsHelpers = require '../helpers/teamshelpers.js'


module.exports =


  createTeam: (browser) ->

    user = utils.getUser(yes)

    browser.url helpers.getUrl()
    browser.maximizeWindow()

    teamsHelpers.setCookie(browser)

    teamsHelpers.openTeamsPage(browser)
    teamsHelpers.fillSignUpFormOnTeamsHomePage(browser, user)
    teamsHelpers.enterTeamURL(browser)
    # teamsHelpers.enterEmailDomains(browser)
    # teamsHelpers.enterInvites(browser)
    teamsHelpers.fillUsernamePasswordForm(browser, user)
    # teamsHelpers.setupStackPage(browser)
    # teamsHelpers.congratulationsPage(browser)
    # teamsHelpers.loginToTeam(browser, user)

    browser.end()


  loginTeam: (browser) ->

    teamsHelpers.loginTeam(browser)
    browser.end()


  openTeamSettings: (browser) ->

    teamsHelpers.loginTeam(browser)
    teamsHelpers.clickTeamSettings(browser)

    browser.end()


  seeTeamNameOnSideBar: (browser) ->

    user = teamsHelpers.loginTeam(browser)

    teamsHelpers.seeTeamNameOnsideBar(browser, user.teamSlug)
    browser.end()


  checkTeamSettings: (browser) ->

    user = teamsHelpers.loginTeam(browser)
    teamsHelpers.clickTeamSettings(browser)

    teamSettingsSelector = '.AppModal--admin-tabs .general-settings'

    browser
      .waitForElementVisible  teamSettingsSelector, 20000
      .waitForElementVisible  'input[name=title]', 20000
      .assert.valueContains   'input[name=title]', user.name
      .waitForElementVisible  'input[name=url]', 20000
      .assert.valueContains   'input[name=url]', user.teamSlug
      .waitForElementVisible  '.avatar-upload .avatar', 20000
      .end()
