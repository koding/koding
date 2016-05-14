utils          = require '../utils/utils.js'
helpers        = require '../helpers/helpers.js'
teamsHelpers   = require '../helpers/teamshelpers.js'
welcomehelpers = require '../helpers/welcomehelpers.js'
welcomeLink    = "#{helpers.getUrl(yes)}/Home/Welcome"

module.exports =
  before: (browser, done) ->
    targetUser1 = utils.getUser no, 1
    targetUser1.role = 'member'
    users = targetUser1
    teamsHelpers.inviteAndJoinWithUsers browser, [users], (result) ->
      done()
  
  checkDashboardbyAdmin: (browser) ->
    welcomehelpers.seeStackView(browser)
    browser.url welcomeLink
    welcomehelpers.seeTeamView(browser)
    browser.url welcomeLink
    browser.pause 3000
    welcomehelpers.seeKDInstall(browser)
    browser.end()


  checkDashboardViewbyMember: (browser) ->
    targetUser1 = utils.getUser no, 1
    teamsHelpers.logoutTeam browser, (res) ->
      teamsHelpers.loginToTeam browser, targetUser1 , no, ->
      browser.pause 3000
      welcomehelpers.seePendingStackView browser
      welcomehelpers.seePersonalStackView(browser)
      browser.url  welcomeLink
      browser.pause 3000
      welcomehelpers.seeKDInstall(browser)
      browser.end()


  checkTeamBilling: (browser) ->
    teamBillingLink = "#{helpers.getUrl(yes)}/Home/team-billing"
    browser
      .url teamBillingLink
      .pause 2000
      .assert.containsText '.HomeAppView--sectionHeader', 'Koding Subscription'
      .waitForElementVisible 'div.HomeAppView--section.HomeTeamBillingPlansList', 20000
      .pause 2000
      
    welcomehelpers.seePricingDetails(browser)
    browser.url teamBillingLink
    welcomehelpers.seeMembers(browser)
    browser.url teamBillingLink
    helpers.fillPaymentForm(browser)
    browser.click 'button.GenericButton.medium.fr'

    welcomehelpers.seePaymentHistory(browser)
    browser.end()

  checkSettingsMenu: (browser) ->
    menuSelector      = '.SidebarMenu.kdcontextmenu .kdlistitemview-contextitem.default'
    myAccountSelector = menuSelector+':nth-of-type(1)'
    dashboardSelector = menuSelector+':nth-of-type(2)'
    supportSelector   = menuSelector+':nth-of-type(3)'
    logoutSelector    = menuSelector+':nth-of-type(4)'
    
    welcomehelpers.gotoSettingsMenu browser, myAccountSelector
    browser
      .assert.containsText 'header.HomeAppView--sectionHeader', 'My Account'
      .pause 3000
    welcomehelpers.gotoSettingsMenu browser, dashboardSelector
    browser
      .waitForElementVisible '.HomeAppView-TabView', 20000
      .pause 3000
    welcomehelpers.gotoSettingsMenu browser, supportSelector
    browser
      .waitForElementVisible '#chatlio-widget .chatlio-widget', 20000
      .pause 3000
    welcomehelpers.gotoSettingsMenu browser, logoutSelector
    browser.pause 1000
    browser.end()
   