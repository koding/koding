helpers = require '../helpers/helpers.js'
assert  = require 'assert'

module.exports =


  becomePaidUser: (browser) ->

    freePlanSelector = '.single-plan.free.current'

    helpers.beginTest(browser)
    browser
      .url                     helpers.getUrl() + '/Pricing'
      .waitForElementVisible   '.content-page.pricing', 20000
      .element 'css selector', freePlanSelector, (result) ->
        if result.status is 0
          helpers.selectPlan(browser, 'developer')
          helpers.fillPaymentForm(browser)
          browser.end()
        else
          browser.end()


    selectedPlanSelector = '.single-plan.' + planType + '.current'

    helpers.beginTest(browser)
    browser
      .url                     helpers.getUrl() + '/Pricing'
      .waitForElementVisible   '.content-page.pricing', 20000
      .element 'css selector', selectedPlanSelector, (result) ->
        if result.status is 0
          browser.end()
        else
          helpers.selectPlan(browser, planType)
          helpers.fillPaymentForm(browser)
          browser.end()
