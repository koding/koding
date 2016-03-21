utils        = require '../utils/utils.js'
teamsHelpers = require '../helpers/teamshelpers.js'


module.exports =


  createTeam: (browser) ->

    utils.getUser(yes)
    teamsHelpers.createTeam(browser)
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

    stackCreatePage       = '.Group-Stack-Templates .get-started'
    getStartedButton      = "#{stackCreatePage} .header button.green"
    skipSetupSelector     = '.footer .skip-setup'
    stackTemplateSelector = '.kdtabhandlecontainer.hide-close-icons .stack-template'
    saveAndTestButton     = '.buttons button:nth-of-type(5)'

    teamsHelpers.loginTeam(browser)
    teamsHelpers.startStackCreate(browser)

    browser
      .waitForElementVisible  getStartedButton, 20000
      .click                  getStartedButton
      .waitForElementVisible  skipSetupSelector, 20000
      .click                  skipSetupSelector
      .waitForElementVisible  stackTemplateSelector, 20000
      .assert.containsText    stackTemplateSelector, 'Stack Template'
      .assert.containsText    saveAndTestButton, 'SAVE & TEST'

