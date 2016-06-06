utils           = require '../utils/utils.js'
helpers         = require '../helpers/helpers.js'
teamBillingLink = "#{helpers.getUrl(yes)}/Home/team-billing"


headerSelector    = '.HomeAppView--sectionHeader'
teamSettings      = '.HomeAppView--section.team-settings'
teamBillingLink   = "#{helpers.getUrl(yes)}/Home/team-billing"
teamBillingList   = 'div.HomeAppView--section.HomeTeamBillingPlansList'
billingForm       = '.HomeAppView--billing-form'
pricingButton     = '.HomeAppView--button:nth-of-type(2)'
viewMemberButton  = '.HomeAppView--button:nth-of-type(1)'
paymentHistory    = 'div.HomeAppView--section.HomeTeamInvoicesList'
paymenthistoryBtn = '.HomeAppView--button.custom-link-view.primary:nth-of-type(2)'
notification      = '.kdnotification.title'

module.exports =

  seeAvailablePaymentSubscription: (browser, callback) ->
    browser
      .pause 2000
      .url teamBillingLink
      .waitForElementVisible headerSelector, 20000
      .assert.containsText headerSelector, 'Koding Subscription'
      .waitForElementVisible teamBillingList, 20000, callback


  redirectPricingDetails: (browser, callback) ->
    browser
      .click pricingButton, (result) ->
        if result.state is 'success'
          helpers.switchBrowser browser, 'http://www.koding.com/pricing'
          browser.pause 1000, callback


  redirectViewMembers: (browser, callback) ->
    browser
      .url teamBillingLink
      .pause 2000
      .click viewMemberButton
      .waitForElementVisible teamSettings, 20000
      .assert.containsText headerSelector, 'Team Settings'
      .pause 1000, callback


  #reimplement after teambilling page is done
  enterCreditCard: (browser, callback) ->

    browser
      .url teamBillingLink
      .waitForElementVisible headerSelector, 20000
      .scrollToElement billingForm
    helpers.fillPaymentForm(browser)
    browser.pause 1000, callback
    #will be reimplemented
    # browser
    #   .click 'button.GenericButton.medium.fr'
    #   .waitForElementVisible notification, 20000


  #reimplement after teambilling page is done
  # deleteCreditCard: (browser, callback) ->
    # browser
      # .click '.HomeAppView--button.custom-link-view.primary:nth-of-type(1)'
      # .pause 3000

  redirectPaymentHistory: (browser, callback) ->
    browser
      .url teamBillingLink
      .waitForElementVisible headerSelector, 20000
      .scrollToElement billingForm
      .click paymenthistoryBtn
      .pause 1000
      .assert.containsText headerSelector, 'Payment History'
      .waitForElementVisible paymentHistory, 20000, callback
