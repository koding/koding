helpers = require '../helpers/helpers.js'
assert  = require 'assert'
environmentHelpers = require '../helpers/environmenthelpers.js'

vmSelector = '.sidebar-machine-box.koding-vm-1'


module.exports =


  seeUpgradeModalForNotPaidUser: (browser) ->

    helpers.beginTest(browser)

    environmentHelpers.clickAddVMButton(browser)

    browser.pause 5000 # wait to see the modal

    browser.element 'css selector', '.env-modal.paid-plan', (result) =>
      if result.status is 0
        browser.end()
      else
        browser
          .waitForElementVisible '.computeplan-modal.free-plan', 20000
          .waitForElementVisible '.computeplan-modal.free-plan .kdmodal-inner', 20000 # Assertion
          .end()


  makeAlwaysOnForNotPaidUser: (browser) ->

    toggleSelector = '.machine-settings-modal .alwayson'

    helpers.beginTest(browser)

    browser.element 'css selector', vmSelector, (result) =>
      if result.status is 0
        browser.end()
      else
        helpers.waitForVMRunning(browser)
        environmentHelpers.openVmSettingsModal(browser)

        browser
          .waitForElementVisible  toggleSelector, 20000
          .click                  toggleSelector + ' .koding-on-off a.knob'
          .pause                  2000
          .waitForElementVisible  '.kdmodal-content a.custom-link-view', 20000 # Assertion
          .end()


  createSnapshotForNonPaidUser: (browser) ->

    messageSelector  = '.kdmodal.computeplan-modal .message'
    message          = 'The Snapshot feature is only available for paid accounts.'

    helpers.beginTest(browser)
    helpers.waitForVMRunning(browser)
    environmentHelpers.attemptCreateSnapshot(browser)

    browser.element 'css selector', '.snapshots .add-view', (result) =>
      if result.status is 0
        browser.end()
      else
        browser
          .waitForElementVisible messageSelector, 20000
          .assert.containsText   messageSelector, message #Assertion
          .end()

