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
    environmentHelpers.nameVM(browser,nickname)

    browser
      .waitForElementVisible nicknameView, 20000
      .assert.containsText   nicknameView, nickname # Assertion

    #Revert Changes for next test to work
    environmentHelpers.nameVM(browser, "koding-vm-0")
    browser.pause 1000 #Doesn't work without it
    browser.end()

  terminateVm: (browser) ->

    terminateSelector       = '.kdmodal.AppModal .advanced .advanced.terminate'
    proceedSelector         = '.kdmodal.with-buttons .kdbutton.red'
    terminatedLabelSelector = '.kdmodal.env-modal .state-label.terminated'

    helpers.beginTest(browser)
    browser.pause 1000
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

### DISABLED - takes too long (10m 41s)
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
          helpers.submitForm(browser, yes)
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
          browser.end()###
