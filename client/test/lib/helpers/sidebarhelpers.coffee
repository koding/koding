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
stackEditorView      = '[testpath=StackEditor-isVisible]'
reinitializeButton   = '[testpath=proceed]'
vmViewSelector       = '.kdview .kdtabpaneview .virtual-machines'
teamnameSelector     = '#kdmaincontainer.with-sidebar #main-sidebar .logo-wrapper .team-name'
dashboardSelector = "#{menuSelector}:nth-of-type(1)"
supportSelector   = "#{menuSelector}:nth-of-type(2)"
logoutSelector    = "#{menuSelector}:nth-of-type(3)"
chatlioWidget     = '.chatlio-widget'
headerSelector    = '.HomeAppView--sectionHeader'
WelcomeView       = '.WelcomeStacksView'

module.exports =

  #Test Stacks Title Click Events
  redirectMyAccountPage: (browser, callback) ->
    browser
      .click sideBarSelector
      .waitForElementVisible headerTitleSelector, 20000
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
  redirectStackSettingsMenu: (browser, callback) ->
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
  redirectDraftStackSettingsMenu: (browser, callback) ->
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


  openSettingsMenu: (browser, callback) ->

    @gotoSettingsMenu browser, dashboardSelector
    browser
      .waitForElementVisible '.HomeWelcomeModal', 20000
    @gotoSettingsMenu browser, supportSelector
    browser
      .waitForElementVisible chatlioWidget, 20000
    @gotoSettingsMenu browser, logoutSelector
    browser.waitForElementVisible '.TeamsModal--login', 20000, callback


  gotoSettingsMenu: (browser, menuItemSelector) ->
    browser
      .waitForElementVisible sideBarSelector, 20000
      .click sideBarSelector
      .waitForElementVisible teamnameSelector, 20000
      .click teamnameSelector
      .waitForElementVisible menuSelector, 2000
      .pause 3000
      .click menuItemSelector
      .pause 3000
