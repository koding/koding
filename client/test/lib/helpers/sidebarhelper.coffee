menuSelector         = '.SidebarMenu.kdcontextmenu .kdlistitemview-contextitem.default'
defaultStackSelector = '.SidebarTeamSection .SidebarStackSection.active h4'
draftStackHeader     = '.SidebarTeamSection .SidebarSection.draft'
editSelector         = "#{menuSelector}:nth-of-type(1)"
reinitSelector       = "#{menuSelector}:nth-of-type(2)"
vmSelector           = "#{menuSelector}:nth-of-type(3)"
sideBarSelector      = '#main-sidebar'
headerTitleSelector  = '.SidebarSection-headerTitle'
notificationSelector = '.kdnotification'
plusIconSelector     = '.SidebarSection-secondaryLink'
createStackEditor    = '.StackEditor-OnboardingModal'
stackEditorView      = '.StackEditorView'
reinitializeButton   = '.kdbutton.solid.red.medium'
vmViewSelector       = '.kdview .kdtabpaneview .virtual-machines'
teamnameSelector     = '#kdmaincontainer.with-sidebar #main-sidebar .logo-wrapper .team-name'

myAccountSelector = "#{menuSelector}:nth-of-type(1)"
dashboardSelector = "#{menuSelector}:nth-of-type(2)"
supportSelector   = "#{menuSelector}:nth-of-type(3)"
logoutSelector    = "#{menuSelector}:nth-of-type(4)"
chatlioWidget     = '.chatlio-widget'

module.exports =

  #Test Stacks Title Click Events
  testStacksTitleEvents: (browser, callback) ->
    browser
      .click sideBarSelector
      .click headerTitleSelector
      .waitForElementVisible '.HomeAppView', 20000
      .pause 1000
      .click sideBarSelector
      .waitForElementVisible headerTitleSelector, 20000
      .moveToElement headerTitleSelector, 0, 0
      .waitForElementVisible plusIconSelector, 20000
      .click plusIconSelector
      .waitForElementVisible createStackEditor, 20000, callback


  #Test Default Stack Settings Edit/Reinitialize/Vms
  testDefaultStackSettings: (browser, callback) ->
    browser
      .click sideBarSelector
      .waitForElementVisible defaultStackSelector, 20000
      .click defaultStackSelector
      .waitForElementVisible menuSelector, 20000
      .pause 1000
      .click editSelector
      .waitForElementVisible stackEditorView, 20000
      .pause 1000

      .click defaultStackSelector
      .waitForElementVisible menuSelector, 20000
      .pause 1000
      .click reinitSelector
      .waitForElementVisible '[testpath=reinitStack]', 20000
      .pause 3000
      .click reinitializeButton
      .waitForElementVisible notificationSelector, 20000
      .assert.containsText   notificationSelector, 'Reinitializing stack...'
      .pause 3000
      .click defaultStackSelector
      .waitForElementVisible menuSelector, 20000
      .pause 1000
      .click vmSelector
      .waitForElementVisible vmViewSelector, 20000, callback


  #Test Draft Stack Settings Edit/Initialize
  testDraftStackSettings: (browser, callback) ->
    browser
      .click sideBarSelector
      .click draftStackHeader
      .waitForElementVisible menuSelector, 20000
      .pause 2000
      .click editSelector
      .waitForElementVisible stackEditorView, 20000
      .pause 2000
      .click sideBarSelector
      .click draftStackHeader
      .waitForElementVisible menuSelector, 20000
      .pause 2000
      .click reinitSelector
      .waitForElementVisible notificationSelector, 20000, callback


  testSettingsMenu: (browser, callback) ->
    @gotoSettingsMenu browser, myAccountSelector
    browser
      .assert.containsText headerSelector, 'My Account'
    @gotoSettingsMenu browser, dashboardSelector
    browser
      .waitForElementVisible WelcomeView, 20000
    @gotoSettingsMenu browser, supportSelector
    browser
      .waitForElementVisible chatlioWidget, 20000
    @gotoSettingsMenu browser, logoutSelector


  gotoSettingsMenu: (browser, menuItemSelector) ->
    browser
      .waitForElementVisible sidebarSelector, 20000
      .click sidebarSelector
      .waitForElementVisible teamnameSelector, 20000
      .click teamnameSelector
      .waitForElementVisible menuSelector, 2000
      .pause 3000
      .click menuItemSelector
      .pause 3000
