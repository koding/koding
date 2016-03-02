environmentHelpers = require '../helpers/environmenthelpers.js'
helpers = require '../helpers/helpers.js'
assert  = require 'assert'

hobbyistPlanSelector = '.single-plan.hobbyist.current'
url                  = helpers.getUrl()
planType             = 'hobbyist'

module.exports =

  before: (browser) ->

    helpers.beginTest(browser)

    browser.url helpers.getUrl() + '/Pricing'

    browser.element 'css selector', hobbyistPlanSelector, (result) ->
      if result.status is -1
        helpers.selectPlan(browser, 'hobbyist')
        helpers.fillPaymentForm(browser, 'hobbyist')
        environmentHelpers.simplifiedSubmitForm(browser)
      else
      	browser.url url


  createNewVmForHobbyistPlan: (browser) ->

    hobbyistPlanSelector = '.single-plan.hobbyist.current'

    environmentHelpers.createNewVmForHobbyistPlan(browser)
    browser.end()


  checkAlwaysOnVmForHobbyistPlan: (browser) ->

    environmentHelpers.checkAlwaysOnVM(browser)
    browser.end()