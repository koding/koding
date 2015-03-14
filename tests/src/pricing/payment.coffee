helpers = require '../helpers/helpers.js'
assert  = require 'assert'

module.exports =


  becomePaidUser: (browser) ->

    planType = 'developer'
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
