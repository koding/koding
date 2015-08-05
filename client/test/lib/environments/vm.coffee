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

  terminateVm: (browser) ->

    terminateSelector       = '.kdmodal.AppModal .advanced .advanced.terminate'
    proceedSelector         = '.kdmodal.with-buttons .kdbutton.red'
    terminatedLabelSelector = '.kdmodal.env-modal .state-label.terminated'

    helpers.beginTest(browser)
    helpers.waitForVMRunning(browser)

    environmentHelpers.openAdvancedSettings(browser)

    browser
      .waitForElementVisible  terminateSelector, 20000
      .click                  terminateSelector
      .waitForElementVisible  proceedSelector, 20000
      .click                  proceedSelector
      .waitForElementVisible  terminatedLabelSelector, 100000
      .assert.containsText    terminatedLabelSelector, "successfully deleted" #Assertion
      .end()

  resizeVm: (browser) ->

    confirmSelector  = ".kdmodal-content .kdbutton.green"
    upgradeSelector  = ".kdmodal-inner .container .custom-link-view"
    envModalSelector = ".env-modal.env-machine-state"
    proceedSelector  = ".kdmodal.with-buttons .kdbutton.red"
    diskSelector     = ".disk-usage .usage-info"

    usageText        = ""

    helpers.beginTest(browser)
    helpers.waitForVMRunning(browser)

    environmentHelpers.openDiskUsageSettings(browser)
    browser.getText diskSelector, (res) ->
      usageText = res.value

      environmentHelpers.openResizeVmModal(browser)
      browser.waitForElementVisible confirmSelector, 20000

      browser.getAttribute confirmSelector, "disabled", (res)->
        if res.value

          browser.click upgradeSelector
          helpers.selectPlan(browser)
          helpers.fillPaymentForm(browser)
          browser.url helpers.getUrl() + "/IDE"
          environmentHelpers.openResizeVmModal(browser)

        browser.waitForElementVisible confirmSelector, 20000
        browser.elements "css selector", ".sliderbar-container .sliderbar-label", (res) ->

          element = res.value[1]
          browser
            .elementIdClick           element.ELEMENT
            .pause                    100 #A little time for UI to update
            .click                    confirmSelector
            .waitForElementVisible    proceedSelector, 20000
            .click                    proceedSelector
            .waitForElementVisible    envModalSelector, 20000
            .waitForElementNotVisible envModalSelector, 500000

          environmentHelpers.openDiskUsageSettings(browser)
          browser.waitForElementVisible diskSelector
          browser.expect.element(diskSelector).text.to.not.equal(usageText) #Assertion
          browser.end()
