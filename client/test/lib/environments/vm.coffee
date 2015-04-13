helpers = require '../helpers/helpers.js'
assert  = require 'assert'
environmentHelpers = require '../helpers/environmenthelpers.js'

modalSelector = '.activity-modal.vm-settings'

module.exports =


  turnOffVm: (browser) ->

    linkSelector  = modalSelector + ' .statustoggle .input-wrapper'

    helpers.beginTest(browser)
    helpers.waitForVMRunning(browser)

    environmentHelpers.openVmSettingsModal(browser)

    browser
      .waitForElementVisible   linkSelector, 20000
      .waitForElementVisible   linkSelector + ' .koding-on-off a.knob', 20000
      .click                   linkSelector + ' .koding-on-off a.knob'
      .waitForElementVisible   '.env-machine-state .kdmodal-content .state-label.stopping', 20000
      .waitForElementVisible   '.env-machine-state .kdmodal-content .state-label.stopped', 300000
      .waitForElementVisible   '.env-machine-state .kdmodal-content .turn-on.state-button', 20000 # Assertion
      .end()


  turnOnVm: (browser)->

    helpers.beginTest(browser)
    helpers.waitForVMRunning(browser)
    browser.end()


  checkVMDiskUsage: (browser) ->

    diskUsageSelector  = modalSelector + ' .disk-usage'
    circularBar        = '.disk-usage-info .circular-progress-bar'

    helpers.beginTest(browser)
    helpers.waitForVMRunning(browser)

    environmentHelpers.openDiskUsageSettings(browser)

    browser
      .waitForElementVisible   diskUsageSelector, 20000
      .click                   diskUsageSelector
      .waitForElementVisible   circularBar, 20000
      .assert.containsText     circularBar + ' span.percentage', '53%' # Assertion
      .end()

