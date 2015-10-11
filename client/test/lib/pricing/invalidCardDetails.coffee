helpers = require '../helpers/helpers.js'
assert  = require 'assert'

tooltipValidation = '.kdtooltip .wrapper'
freePlanSelector  = '.single-plan.free.current'


module.exports = 

  checkInvalidCardNumber: (browser) ->

    helpers.beginTest(browser)

    inputWrapper = '.input-wrapper'

    browser
      .url                     helpers.getUrl() + '/Pricing'
      .waitForElementVisible   '.content-page.pricing', 20000
      .waitForElementVisible   '.current', 20000
      .element 'css selector', freePlanSelector, (result) ->
        if result.status is 0
          helpers.selectPlan(browser, 'developer')
          helpers.fillPaymentForm(browser, 'developer', false, true, false, false, false, false)
          helpers.submitForm(browser, false)

          browser
            .waitForElementVisible      inputWrapper + ' .validation-error', 5000
            .assert.containsText        tooltipValidation, 'Card number is not valid'
            .end()
        else
          browser.end()


  checkInvalidCVC: (browser) ->

    helpers.beginTest(browser)

    cvcInputField = ' [name=cardCVC]'

    browser
      .url                     helpers.getUrl() + '/Pricing'
      .waitForElementVisible   '.content-page.pricing', 20000
      .waitForElementVisible   '.current', 20000
      .element 'css selector', freePlanSelector, (result) ->
        if result.status is 0
          helpers.selectPlan(browser, 'developer')
          helpers.fillPaymentForm(browser, 'developer', false, false, true, false, false, false)
          helpers.submitForm(browser, false)

          browser
            .waitForElementVisible      cvcInputField, 5000
            .assert.containsText        tooltipValidation, 'CVC is not valid'
            .end()
        else
          browser.end()


  checkInvalidExpirationMonth: (browser) ->

    helpers.beginTest(browser)

    cardMonthInputField = '[name=cardMonth]'

    browser
      .url                     helpers.getUrl() + '/Pricing'
      .waitForElementVisible   '.content-page.pricing', 20000
      .waitForElementVisible   '.current', 20000
      .element 'css selector', freePlanSelector, (result) ->
        if result.status is 0
          helpers.selectPlan(browser, 'developer')
          helpers.fillPaymentForm(browser, 'developer', false, false, false, true, false, false)
          helpers.submitForm(browser, false)

          browser
            .waitForElementVisible      cardMonthInputField, 5000
            .assert.containsText        tooltipValidation, 'Invalid month!'
            .end()
        else
          browser.end()


  checkInvalidExpirationYear: (browser) ->

    helpers.beginTest(browser)

    cardYearInputField = '[name=cardYear]'

    browser
      .url                     helpers.getUrl() + '/Pricing'
      .waitForElementVisible   '.content-page.pricing', 20000
      .waitForElementVisible   '.current', 20000
      .element 'css selector', freePlanSelector, (result) ->
        if result.status is 0
          helpers.selectPlan(browser, 'developer')
          helpers.fillPaymentForm(browser, 'developer', false, false, false, false, true, false)
          helpers.submitForm(browser, false)

          browser
            .waitForElementVisible      cardYearInputField, 5000
            .assert.containsText        tooltipValidation, 'Invalid year!'
            .end()
        else
          browser.end()

  checkUpgradePlanButtonWithInvalidData: (browser) ->
    helpers.beginTest(browser)
    
    browser
      .url                     helpers.getUrl() + '/Pricing'
      .waitForElementVisible   '.content-page.pricing', 20000
      .waitForElementVisible   '.current', 20000
      .element 'css selector', freePlanSelector, (result) ->
        if result.status is 0
          helpers.selectPlan(browser, 'developer')
          helpers.fillPaymentForm(browser, 'developer', false, true, true, true, true, true)
          helpers.submitForm(browser, false)

          browser
            .end()
        else
          browser.end()
