helpers  = require '../helpers/helpers.js'
utils    = require '../utils/utils.js'
teamsHelpers = require '../helpers/teamshelpers.js'


module.exports =


  createTeam: (browser) ->

    user = utils.getUser(yes)
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

    modalSelector         = '.kdmodal-content .AppModal-content'
    providerSelector      = "#{modalSelector} .stack-onboarding .provider-selection"
    machineSelector       = "#{providerSelector} .providers"
    stackPreview          = "#{modalSelector} .stack-preview"
    codeSelector          = "#{stackPreview} .has-markdown"
    footerSelector        = "#{modalSelector} .stacks .footer"
    nextButtonSelector    = "#{footerSelector} button.next"
    awsSelector           = "#{machineSelector} .aws"
    configurationSelector = "#{modalSelector} .configuration .server-configuration"
    inputSelector         = "#{configurationSelector} .Database"
    mysqlSelector         = "#{inputSelector} .mysql input.checkbox + label"
    postgresqlSelector    = "#{inputSelector} .postgresql input.checkbox + label"
    server1PageSelector   = "#{modalSelector} .code-setup .server-1"
    githubSelector        = "#{server1PageSelector} .box-wrapper .github"
    bitbucketSelector     = "#{server1PageSelector} .box-wrapper .bitbucket"
    editorSelector        = "#{modalSelector} .editor-main"

    teamsHelpers.loginTeam(browser)
    teamsHelpers.startStackCreate(browser)

    browser
      .waitForElementVisible  providerSelector, 20000
      .waitForElementVisible  awsSelector, 20000
      .waitForElementVisible  "#{machineSelector} .vagrant" , 20000 # Assertion
      .click                  awsSelector
      .waitForElementVisible  stackPreview, 20000
      .waitForElementVisible  codeSelector, 20000
      .assert.containsText    codeSelector, 'koding_group_slug'
      .waitForElementVisible  footerSelector, 20000
      .waitForElementVisible  nextButtonSelector, 20000
      .pause                  2000 # wait for animation
      .click                  nextButtonSelector
      .waitForElementVisible  configurationSelector, 20000
      .pause                  2000 # wait for animation
      .waitForElementVisible  mysqlSelector, 20000
      .click                  mysqlSelector
      .pause                  2000 # wait for animation
      .waitForElementVisible  postgresqlSelector, 20000
      .click                  postgresqlSelector
      .waitForElementVisible  stackPreview, 20000
      .assert.containsText    codeSelector, 'mysql-server postgresql'
      .waitForElementVisible  nextButtonSelector, 20000
      .pause                  2000 # wait for animation
      .click                  nextButtonSelector
      .waitForElementVisible  server1PageSelector, 20000
      .waitForElementVisible  githubSelector, 20000 # Assertion
      .waitForElementVisible  bitbucketSelector, 20000 # Assertion
      .waitForElementVisible  nextButtonSelector, 20000
      .moveToElement          nextButtonSelector, 15, 10
      .pause                  2000
      .click                  nextButtonSelector
      .waitForElementVisible  "#{modalSelector} .define-stack-view", 20000
      .waitForElementVisible  editorSelector, 20000
      .pause                  1000
      .assert.containsText    editorSelector, 'aws_instance'
      .end()
