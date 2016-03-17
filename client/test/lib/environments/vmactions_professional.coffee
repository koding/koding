environmentHelpers = require '../helpers/environmenthelpers.js'
helpers = require '../helpers/helpers.js'
assert  = require 'assert'

professionalPlanSelector = '.single-plan.professional.current'
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


  checkMaximum5VmsForProfessionalPlan: (browser) ->

    vmSelector       = '.activity-sidebar .machines-wrapper .vms.my-machines .koding-vm-'
    thirdVmSelector  = '.activity-sidebar .machines-wrapper .koding-vm-2'
    vmSelector1      = "#{vmSelector}1"
    vmSelector2      = "#{vmSelector}2"
    vmSelector3      = "#{vmSelector}3"
    vmSelector4      = "#{vmSelector}4"
    usageVmSelector  = '.kdview.storage-container .kdview:nth-of-type(3)'
    remainingSlots   = 'Remaining VM slots: 0/5'
    usedStorage      = 'You will be using 28GB/50GB storage'

    browser.element 'css selector', thirdVmSelector, (result) ->
      if result.status is -1
        browser.element 'css selector', secondVmSelector, (result) ->
          if result.status is -1
            environmentHelpers.addNewVM(browser, vmSelector1)
        environmentHelpers.addNewVM(browser, vmSelector2)
        environmentHelpers.addNewVM(browser, vmSelector3)
        environmentHelpers.addNewVM(browser, vmSelector4)
        environmentHelpers.addNewVM(browser, usageVmSelector, yes, remainingSlots, usedStorage)

    browser.end()
