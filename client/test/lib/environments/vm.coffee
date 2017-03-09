helpers = require '../helpers/helpers.js'
assert  = require 'assert'
environmentHelpers = require '../helpers/environmenthelpers.js'
modalSelector = '.machine-settings-modal.AppModal'

module.exports =

  turnOffVm: (browser) ->

    linkSelector  = modalSelector + ' .AppModal-form'
    vmStateModal  = '.env-machine-state .kdmodal-content'

    helpers.beginTest(browser)
    helpers.waitForVMRunning(browser)

    environmentHelpers.openGeneralSettings(browser)

    browser
      .waitForElementVisible   linkSelector, 20000
      .waitForElementVisible   linkSelector + ' .statustoggle', 20000
      .click                   linkSelector + ' .statustoggle .koding-on-off.on'
      .waitForElementVisible   vmStateModal + ' .state-label.stopping', 20000
      .waitForElementVisible   vmStateModal + ' .state-label.stopped', 300000
      .waitForElementVisible   vmStateModal + ' .turn-on.state-button', 20000 # Assertion
      .end()


  turnOnVm: (browser) ->

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
      .getText circularBar + ' span.percentage', (result) ->
        percentage = parseInt result.value.replace('%', '')
        assert.ok percentage > 40 # Assertion

        browser.end()


  updateVMNickname: (browser) ->

    paragraph     = helpers.getFakeText()
    nickname      = paragraph.split(' ')[0]
    nicknameView  = modalSelector + ' .nickname .input-wrapper .kdview'

    helpers.beginTest(browser)
    helpers.waitForVMRunning(browser)

    environmentHelpers.openGeneralSettings(browser)
    environmentHelpers.nameVM(browser, nickname)

    browser
      .waitForElementVisible nicknameView, 20000
      .assert.containsText   nicknameView, nickname # Assertion

    #Revert Changes for next test to work
    environmentHelpers.nameVM(browser, 'koding-vm-0')
    browser.pause 1000 #Doesn't work without it
    browser.end()
