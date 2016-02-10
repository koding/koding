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
          helpers.submitForm(browser, yes, yes)
          environmentHelpers.createNewVmForHobbyistPlan(browser)
          browser.end()
        else
          browser.url url
          environmentHelpers.createNewVmForHobbyistPlan(browser)
          browser.end()


  checkAlwaysOnVmForHobbyistPlan: (browser) ->

    hobbyistPlanSelector = '.single-plan.hobbyist.current'
    sidebarSelector      = '.kdview.sidebar-machine-box .vm'
    alwaysOnSelector     = '.kdinput.koding-on-off.statustoggle.small'
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
          helpers.submitForm(browser, yes, yes)
        else
          browser.url url

    browser
      .moveToElement          sidebarSelector, 10, 10
      .waitForElementVisible  "#{sidebarSelector} span", 20000
      .click                  "#{sidebarSelector} span"
      .waitForElementVisible  "#{alwaysOnSelector}.off", 20000
      .click                  "#{alwaysOnSelector}.off"
      .waitForElementVisible  "#{alwaysOnSelector}.on", 20000
      .end()