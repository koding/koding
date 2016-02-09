environmentHelpers = require '../helpers/environmenthelpers.js'
helpers = require '../helpers/helpers.js'
assert  = require 'assert'

module.exports =


  createNewVmForHobbyistPlan: (browser) ->

    hobbyistPlanSelector = '.single-plan.hobbyist.current'
    submitButton         = 'button.submit-btn'
    url                  = helpers.getUrl()

    helpers.beginTest(browser)
    browser
      .url                     helpers.getUrl() + '/Pricing'
      .waitForElementVisible   '.content-page.pricing', 20000
      .waitForElementVisible   '.current', 20000
      .element 'css selector', hobbyistPlanSelector, (result) ->
        if result.status is -1
          helpers.selectPlan(browser, 'hobbyist')
          helpers.fillPaymentForm(browser, 'hobbyist')
        
          browser
            .waitForElementVisible   submitButton, 20000
            .click                   submitButton
            .waitForElementVisible   '.kdmodal-content .success-msg', 20000
            .click                   submitButton
          environmentHelpers.createNewVmForHobbyistPlan(browser)
          browser.end()
        else
          browser.url url
          environmentHelpers.createNewVmForHobbyistPlan(browser)
          browser.end()
