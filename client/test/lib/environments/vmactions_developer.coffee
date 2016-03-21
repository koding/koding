environmentHelpers = require '../helpers/environmenthelpers.js'
helpers = require '../helpers/helpers.js'
assert  = require 'assert'

developerPlanSelector = '.single-plan.developer.current'
url                   = helpers.getUrl()

module.exports =

  before: (browser) ->

    helpers.beginTest(browser)

    browser.url helpers.getUrl() + '/Pricing'

    browser.element 'css selector', developerPlanSelector, (result) ->
      if result.status is -1
        helpers.selectPlan(browser)
        helpers.fillPaymentForm(browser)
        environmentHelpers.simplifiedSubmitForm(browser)
      else
        browser.url url


  checkAlwaysOnVmForDevelopmentPlan: (browser) ->

    environmentHelpers.checkAlwaysOnVM(browser)
    browser.end()


  checkMaximum3VmsForDeveloperPlan: (browser) ->

    vmSelector       = '.activity-sidebar .machines-wrapper .vms.my-machines .koding-vm-'
    secondVmSelector = '.activity-sidebar .machines-wrapper .koding-vm-1'
    vmSelector1      = "#{vmSelector}1"
    vmSelector2      = "#{vmSelector}2"
    usageVmSelector  = '.kdview.storage-container .kdview:nth-of-type(3)'
    remainingSlots   = 'Remaining VM slots: 0/3'
    usedStorage      = 'You will be using 18GB/25GB storage'

    browser.element 'css selector', secondVmSelector, (result) ->
      if result.status is -1
        environmentHelpers.addNewVM(browser, vmSelector1)
        environmentHelpers.addNewVM(browser, vmSelector2)
        environmentHelpers.addNewVM(browser, usageVmSelector, yes, remainingSlots, usedStorage)

    browser.end()


