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

    teamsHelpers.loginTeam(browser)
    teamsHelpers.createStack(browser, yes)
    browser.end()


  checkNotReadyIconDisplayedForStacks: (browser) ->

    saveAndTestButton           = '.buttons button:nth-of-type(5)'
    stackTemplateSelector       = '.kdtabhandlecontainer.hide-close-icons .stack-template'
    stacksLogsSelector          = '.step-define-stack .kdscrollview'
    myStackTemplatesButton      = '.kdview.kdtabhandle-tabs .my-stack-templates'
    notReadyIconSelector        = '.kdlistitemview-default.stacktemplate-item .stacktemplate-info .not-ready'
    stackTemplateSettingsButton = '.kdbutton.stack-settings-menu'
    deleteButton                = '.kdlistview-contextmenu.expanded .delete'
    confirmDeleteButton         = '.kdview.kdmodal-buttons .solid.red .button-title'

    teamsHelpers.loginTeam(browser)
    teamsHelpers.createStack(browser, yes)

    browser
      .click                      saveAndTestButton
      .pause                      2000
      .waitForElementVisible      stacksLogsSelector, 20000
      .assert.containsText        stacksLogsSelector, 'An error occured: Required credentials are not provided yet'
      .click                      myStackTemplatesButton
      .waitForElementVisible      notReadyIconSelector, 30000
      .assert.containsText        notReadyIconSelector, 'NOT READY'
      .waitForElementVisible      stackTemplateSettingsButton, 20000
      .click                      stackTemplateSettingsButton
      .waitForElementVisible      deleteButton, 20000
      .click                      deleteButton
      .waitForElementVisible      confirmDeleteButton, 20000
      .click                      confirmDeleteButton
      .pause                      2000
      .waitForElementVisible      stackTemplateSelector, 20000
      .assert.containsText        stackTemplateSelector, 'Stack Template'
      .assert.containsText        saveAndTestButton, 'SAVE & TEST'
      .end()

