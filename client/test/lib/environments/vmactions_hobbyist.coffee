environmentHelpers = require '../helpers/environmenthelpers.js'
helpers = require '../helpers/helpers.js'
assert  = require 'assert'

hobbyistPlanSelector = '.single-plan.hobbyist.current'
url                  = helpers.getUrl()

module.exports =

  before: (browser) ->

    helpers.beginTest(browser)

    browser.url helpers.getUrl() + '/Pricing'

    browser.element 'css selector', hobbyistPlanSelector, (result) ->
      if result.status is -1
        helpers.selectPlan(browser, 'hobbyist')
        helpers.fillPaymentForm(browser, 'hobbyist')
        helpers.submitForm(browser, yes, yes)
      else
      	browser.url url


  createNewVmForHobbyistPlan: (browser) ->

    hobbyistPlanSelector = '.single-plan.hobbyist.current'

    environmentHelpers.createNewVmForHobbyistPlan(browser)
    browser.end()


  checkAlwaysOnVmForHobbyistPlan: (browser) ->

    sidebarSelector  = '.kdview.sidebar-machine-box .vm'
    alwaysOnSelector = '.kdinput.koding-on-off.statustoggle.small'

    browser
      .waitForElementVisible  sidebarSelector, 20000
      .moveToElement          sidebarSelector, 10, 10
      .waitForElementVisible  "#{sidebarSelector} span", 20000
      .click                  "#{sidebarSelector} span"
      .pause                  1000
      .element 'css selector', "#{alwaysOnSelector}.off", (result) ->
        if result.status is 0
          browser
            .click                  "#{alwaysOnSelector}.off"
            .waitForElementVisible  "#{alwaysOnSelector}.on", 20000
      browser.end()