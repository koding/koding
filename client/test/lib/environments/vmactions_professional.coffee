environmentHelpers = require '../helpers/environmenthelpers.js'
helpers = require '../helpers/helpers.js'
assert  = require 'assert'

professionalPlanSelector = '.single-plan.hobbyist.professional.current'
secondVmSelector         = '.activity-sidebar .machines-wrapper .koding-vm-1'
url                      = helpers.getUrl()

module.exports =

  before: (browser) ->

    helpers.beginTest(browser)

    browser.url helpers.getUrl() + '/Pricing'

    browser.element 'css selector', professionalPlanSelector, (result) ->
      if result.status is -1
        helpers.selectPlan(browser, 'professional')
        helpers.fillPaymentForm(browser, 'professional')
        environmentHelpers.simplifiedSubmitForm(browser)
      else
      	browser.url url


  check2AlwaysOnVmProfessionalPlan: (browser, secondVM = no) ->


    browser.element 'css selector', secondVmSelector, (result) ->
      if result.status is -1
        environmentHelpers.setAlwaysOnVm(browser, yes)

    browser.end()
