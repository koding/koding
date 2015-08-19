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
      .assert.containsText     circularBar + ' span.percentage', '53%' # Assertion
      .end()

  updateVMNickname: (browser) ->

    vmModal       = modalSelector + ' .AppModal-form'
    paragraph     = helpers.getFakeText()
    nickname      = paragraph.split(' ')[0]
    nicknameInput = vmModal + ' .nickname input[name=nickEdit]'
    nicknameView  = vmModal + ' .nickname .input-wrapper .kdview'

    helpers.beginTest(browser)
    helpers.waitForVMRunning(browser)

    environmentHelpers.openGeneralSettings(browser)

    browser
      .waitForElementVisible  vmModal, 20000
      .waitForElementVisible  vmModal + ' .nickname', 20000
      .click                  vmModal + ' .nickname .edit'
      .waitForElementVisible  nicknameInput, 20000
      .clearValue             nicknameInput
      .setValue               nicknameInput, nickname + '\n'
      .waitForElementVisible  nicknameView, 20000
      .assert.containsText    nicknameView, nickname # Assertion
      .end()

  terminateVMFreeUser: (browser) ->

    accountModalSelector = '.AppModal--account.AppModal'
    billingTabSelector   = accountModalSelector + ' .AppModal-navItem.billing'
    freePlan             = 'Free'
    planSelector         = accountModalSelector + ' .AppModal-content .subscription span[data-paths=planTitle]'
    advancedSelector     = modalSelector + ' .advanced'
    terminateSelector    = modalSelector + ' .AppModal-content .terminate figure'
    removeButton         = '.kdmodal-inner button.red'
    createNewVMButton    = '.env-modal .kdmodal-inner button.turn-on'

    helpers.beginTest(browser)
    helpers.openAccountPage(browser)

    browser
      .waitForElementVisible  billingTabSelector, 20000
      .click                  billingTabSelector
      .waitForElementVisible  planSelector, 20000
      .assert.containsText    planSelector, freePlan
      .click                  '.kdmodal-inner .close-icon'

    helpers.waitForVMRunning(browser)

    environmentHelpers.openGeneralSettings(browser)

    browser
      .waitForElementVisible  advancedSelector, 20000
      .click                  advancedSelector
      .waitForElementVisible  terminateSelector, 20000
      .click                  terminateSelector
      .waitForElementVisible  removeButton, 20000
      .click                  removeButton
      .waitForElementVisible  createNewVMButton, 300000
      .click                  createNewVMButton

    environmentHelpers.clickAddKodingVMButton(browser)

    browser.pause 2000

    helpers.waitForVMRunning(browser)

    browser.end()
