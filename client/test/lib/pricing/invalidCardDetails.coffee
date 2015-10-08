helpers = require '../helpers/helpers.js'
assert  = require 'assert'

upgradePlanLink   = '.avatararea-popup .kdview [href="/Pricing"]'
upgradePlanButton = '.kdmodal-inner .green'
upgradePlanName   = '.plan-name'
tooltipValidation = '.kdtooltip'

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
          .waitForElementVisible      upgradePlanName, 10000
          .assert.containsText        upgradePlanName, 'Developer Plan'
          .assert.containsText        '.card-number', 'Card Number'
          .setValue                   inputWrapper + ' .kdinput', '111111111111'
          .waitForElementVisible      inputWrapper + ' .validation-error', 5000
          .assert.containsText        tooltipValidation, 'Card number is not valid'

          .expect.element(upgradePlanButton).to.not.be.enabled
          browser.end()
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
          .waitForElementVisible      upgradePlanName, 10000
          .assert.containsText        upgradePlanName, 'Developer Plan'
          .assert.containsText        '.cardcvc .cvc', 'CVC'
          .setValue                   cvcInputField, '12345'
          .waitForElementVisible      cvcInputField, 5000
          .assert.containsText        tooltipValidation, 'CVC is not valid'

          .expect.element(upgradePlanButton).to.not.be.enabled
          browser.end()
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
          .waitForElementVisible      upgradePlanName, 10000
          .assert.containsText        upgradePlanName, 'Developer Plan'
          .assert.containsText        '.cardmonth .exp-date', 'Exp. Date'
          .setValue                   cardMonthInputField, '88'
          .waitForElementVisible      cardMonthInputField, 5000
          .assert.containsText        tooltipValidation, 'Invalid month!'

          .expect.element(upgradePlanButton).to.not.be.enabled
          browser.end()
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
          .waitForElementVisible      upgradePlanName, 10000
          .assert.containsText        upgradePlanName, 'Developer Plan'
          .setValue                   cardYearInputField, '1999'
          .waitForElementVisible      cardYearInputField, 5000
          .assert.containsText        tooltipValidation, 'Invalid year!'

          .expect.element(upgradePlanButton).to.not.be.enabled
          browser.end()
        else
          browser.end()
