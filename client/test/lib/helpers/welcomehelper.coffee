utils          = require '../utils/utils.js'
helpers        = require '../helpers/helpers.js'
teamsHelpers   = require '../helpers/teamshelpers.js'
welcomeLink    = "#{helpers.getUrl(yes)}/Home/Welcome"

WelcomeView       = '.WelcomeStacksView'
stackLink         = "#{WelcomeView} ul.bullets li:nth-of-type(1)"
teamLink          = "#{WelcomeView} ul.bullets li:nth-of-type(2)"
installKDLink     = "#{WelcomeView} ul.bullets li:nth-of-type(3)"
headerSelector    = '.HomeAppView--sectionHeader'
stackEditor       = '.StackEditor-OnboardingModal'
teamSettings      = '.HomeAppView--section.team-settings'
kodingUtilities   = '.HomeAppView--section.kd-cli'

teamBillingLink   = "#{helpers.getUrl(yes)}/Home/team-billing"
teamBillingList   = 'div.HomeAppView--section.HomeTeamBillingPlansList'
billingForm       = '.HomeAppView--billing-form'
pricingButton     = '.HomeAppView--button:nth-of-type(2)'
viewMemberButton  = '.HomeAppView--button:nth-of-type(1)'
paymentHistory    = 'div.HomeAppView--section.HomeTeamInvoicesList'
paymenthistoryBtn = '.HomeAppView--button.custom-link-view.primary:nth-of-type(2)'

menuSelector      = '.SidebarMenu.kdcontextmenu .kdlistitemview-contextitem.default'
myAccountSelector = "#{menuSelector}:nth-of-type(1)"
dashboardSelector = "#{menuSelector}:nth-of-type(2)"
supportSelector   = "#{menuSelector}:nth-of-type(3)"
logoutSelector    = "#{menuSelector}:nth-of-type(4)"
chatlioWidget     = '.chatlio-widget'

pendingStack      = "#{WelcomeView} ul.bullets li:nth-of-type(1)"
userstackLink     = "#{WelcomeView} ul.bullets li:nth-of-type(2)"

module.exports =

  #Test Dashboard Screen for Admin
  dashboardScreenAdmin: (browser, callback) ->

    browser
      .waitForElementVisible WelcomeView, 20000
      .click stackLink
      .waitForElementVisible stackEditor, 20000
      .url welcomeLink
      .pause 2000
      .waitForElementVisible WelcomeView, 20000
      .click teamLink
      .waitForElementVisible teamSettings, 20000
      .url welcomeLink
      .pause 2000
      .waitForElementVisible WelcomeView, 20000
      .click installKDLink
      .waitForElementVisible kodingUtilities, 20000, callback


  #Test Dashboard Screen for User
  dashboardScreenMember: (browser) ->
    targetUser1 = utils.getUser no, 1
    teamsHelpers.loginToTeam browser, targetUser1 , no, ->
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
        .click installKDLink
        .waitForElementVisible kodingUtilities, 20000

   #Test Team Billing Screen
  testTeamBillingScreen: (browser, callback) ->
    browser
      .pause 2000
      .url teamBillingLink
      .waitForElementVisible headerSelector, 20000
      .assert.containsText headerSelector, 'Koding Subscription'
      .waitForElementVisible teamBillingList, 20000
      .click pricingButton, (result) ->
        if result.state is 'success'
          helpers.switchBrowser browser, 'http://www.koding.com/pricing'

      .url teamBillingLink
      .pause 2000
      .click viewMemberButton
      .waitForElementVisible teamSettings, 20000
      .assert.containsText headerSelector, 'Team Settings'
      .url teamBillingLink
    helpers.fillPaymentForm(browser)

    #Save Card and Remove Card will be reimplement after Billing Screen is completed
    #browser
    # .click 'button.GenericButton.medium.fr'
    # .scrollToElement billingForm
    # .click '.HomeAppView--button.custom-link-view.primary:nth-of-type(1)'
    # .pause 3000
    browser
      .scrollToElement billingForm
      .click paymenthistoryBtn
      .pause 1000
      .assert.containsText headerSelector, 'Payment History'
      .waitForElementVisible paymentHistory, 20000, callback
