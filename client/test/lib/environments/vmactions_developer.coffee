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
        browser
          .waitForElementVisible   'button.submit-btn', 20000
          .click                   'button.submit-btn'
          .waitForElementVisible   '.kdmodal-content .success-msg', 20000
          .click                   'button.submit-btn'
      else
      	browser.url url


  checkMaximum3VmsForDeveloperPlan: (browser) ->

    vmSelector       = '.activity-sidebar .machines-wrapper .vms.my-machines .koding-vm-'
    secondVmSelector = '.activity-sidebar .machines-wrapper .koding-vm-1'
    vmSelector1      = "#{vmSelector}1"
    vmSelector2      = "#{vmSelector}2"
    usageVmSelector  = '.kdview.storage-container .kdview:nth-of-type(3)'

    browser.element 'css selector', secondVmSelector, (result) ->
      if result.status is -1
        environmentHelpers.addNewVM(browser, vmSelector1)
        environmentHelpers.addNewVM(browser, vmSelector2)
        environmentHelpers.addNewVM(browser, usageVmSelector, yes)

    browser.end()