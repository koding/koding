utils           = require '../utils/utils.js'
helpers         = require '../helpers/helpers.js'
teamBillingLink = "#{helpers.getUrl(yes)}/Home/team-billing"

teamBillingLink   = "#{helpers.getUrl(yes)}/Home/team-billing"
teamBillingList   = 'div.HomeAppView--section.HomeTeamBillingPlansList'
billingForm       = '.HomeAppView--billing-form'
pricingButton     = '.HomeAppView--button:nth-of-type(2)'
viewMemberButton  = '.HomeAppView--button:nth-of-type(1)'
paymentHistory    = 'div.HomeAppView--section.HomeTeamInvoicesList'
paymenthistoryBtn = '.HomeAppView--button.custom-link-view.primary:nth-of-type(2)'
module.exports =
  
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
    
  testTeamBillingScreen: (browser, callback) ->
    browser
      .scrollToElement billingForm
      .click paymenthistoryBtn
      .pause 1000
      .assert.containsText headerSelector, 'Payment History'
      .waitForElementVisible paymentHistory, 20000, callback
