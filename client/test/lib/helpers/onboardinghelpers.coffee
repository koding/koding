utils          = require '../utils/utils.js'
helpers        = require '../helpers/helpers.js'
teamsHelpers   = require '../helpers/teamshelpers.js'
welcomeLink    = "#{helpers.getUrl(yes)}/Welcome"

WelcomeView       = '.WelcomeStacksView'
stackLink         = "#{WelcomeView} ul.bullets li:nth-of-type(1)"
credentialLink    = "#{WelcomeView} ul.bullets li:nth-of-type(2)"
teamLink          = "#{WelcomeView} ul.bullets li:nth-of-type(4)"
installKDLink     = "#{WelcomeView} ul.bullets li:nth-of-type(5)"
headerSelector    = '.HomeAppView--sectionHeader'
stackEditor       = '.StackEditor-OnboardingModal'
teamSettings      = '.HomeAppView--section.send-invites'
kodingUtilities   = '.HomeAppView--section.kd-cli'

menuSelector      = '.SidebarMenu.kdcontextmenu .kdlistitemview-contextitem.default'
dashboardSelector = "#{menuSelector}:nth-of-type(1)"
supportSelector   = "#{menuSelector}:nth-of-type(2)"
logoutSelector    = "#{menuSelector}:nth-of-type(3)"
chatlioWidget     = '.chatlio-widget'

pendingStack         = "#{WelcomeView} ul.bullets li:nth-of-type(1)"
userstackLink        = "#{WelcomeView} ul.bullets li:nth-of-type(2)"
memberInstallKDLink  = "#{WelcomeView} ul.bullets li:nth-of-type(5)"
sidebar              = '#main-sidebar'

module.exports =

  #Test Onboarding Screen for Admin
  openOnboarding: (browser, callback) ->
    browser
      .url welcomeLink
      .pause 2000
      .waitForElementVisible WelcomeView, 20000, callback

  openStackEditor: (browser, callback) ->
    browser
      .click stackLink
      .waitForElementVisible stackEditor, 20000, callback

  openCredential: (browser, callback) ->
    browser
      .click credentialLink
      .waitForElementVisible stackEditor, 20000, callback

  openMyTeamScreen: (browser, callback) ->
    browser
      .click teamLink
      .waitForElementVisible sendInvites, 20000, callback

  installKDLink: (browser, callback) ->
    browser
      .click installKDLink
      .waitForElementVisible kodingUtilities, 20000
      .click sidebar
      .pause 1000, callback


  #Test Onboarding Screen for User
  onboardingScreenMember: (browser) ->
    targetUser1 = utils.getUser no, 1
    teamsHelpers.loginToTeam browser, targetUser1 , no, '', ->
      browser
        .pause 2000
        .waitForElementVisible WelcomeView, 20000
        .assert.containsText   pendingStack, 'Your Team Stack is Pending'
        .waitForElementVisible WelcomeView, 20000
        .click userstackLink
        .waitForElementVisible stackEditor, 20000
        .url  welcomeLink
        .pause 2000
        .waitForElementVisible WelcomeView, 20000
        .click memberInstallKDLink
        .waitForElementVisible kodingUtilities, 20000
