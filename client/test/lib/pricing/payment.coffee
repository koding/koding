helpers = require '../helpers/helpers.js'
assert  = require 'assert'

module.exports =


  becomePaidUser: (browser) ->

    freePlanSelector = '.single-plan.free.current'

    helpers.beginTest(browser)
    browser
      .url                     helpers.getUrl() + '/Pricing'
      .waitForElementVisible   '.content-page.pricing', 20000
      .waitForElementVisible   '.current', 20000
      .element 'css selector', freePlanSelector, (result) ->
        if result.status is 0
          helpers.selectPlan(browser, 'developer')
          helpers.fillPaymentForm(browser)
          browser.end()
        else
          browser.end()


  upgradeAccount: (browser) ->

    planType = 'professional'
    selectedPlanSelector = '.single-plan.' + planType + '.current'

    helpers.beginTest(browser)
    browser
      .url                     helpers.getUrl() + '/Pricing'
      .waitForElementVisible   '.content-page.pricing', 20000
      .waitForElementVisible   '.current', 20000
      .element 'css selector', selectedPlanSelector, (result) ->
        if result.status is 0
          browser.end()
        else
          helpers.selectPlan(browser, planType)

          browser
            .waitForElementVisible   '.payment-modal', 20000
            .click                   '.payment-modal button'
            .waitForElementVisible   '.payment-modal', 20000
            .pause                   5000
            .click                   '.payment-modal button'
            .waitForElementVisible   '[testpath=main-sidebar]', 20000
            .url                     helpers.getUrl() + '/Pricing'
            .waitForElementVisible   '.content-page.pricing', 20000
            .waitForElementVisible   '.single-plan.' + planType + '.current', 20000
            .end()


  downgradeAccount: (browser) ->

    helpers.beginTest(browser)
    browser
      .url                     helpers.getUrl() + '/Pricing'
      .waitForElementVisible   '.content-page.pricing', 20000

    helpers.selectPlan(browser, 'developer')

    browser
      .waitForElementVisible   '.payment-modal', 20000
      .click                   '.payment-modal button'
      .waitForElementVisible   '.payment-modal', 20000
      .pause                   5000
      .click                   '.payment-modal button'
      .waitForElementVisible   '[testpath=main-sidebar]', 20000
      .url                     helpers.getUrl() + '/Pricing'
      .waitForElementVisible   '.content-page.pricing', 20000
      .waitForElementVisible   '.single-plan.' + 'developer' + '.current', 20000
      .end()


