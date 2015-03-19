helpers = require '../helpers/helpers.js'
assert  = require 'assert'
environmentHelpers = require '../helpers/environmenthelpers.js'


module.exports =


  seeUpgradeModalForNotPaidUser: (browser) ->

    helpers.beginTest(browser)
    helpers.waitForVMRunning(browser)

    environmentHelpers.clickAddVMButton(browser)

    browser.pause 5000 # wait to see the modal

    browser.element 'css selector', '.env-modal.paid-plan', (result) =>
      if result.status is 0
        browser.end()
      else
        browser
          .waitForElementVisible '.computeplan-modal.free-plan .kdmodal-inner', 20000 # Assertion
          .end()


  makeAlwaysOnForNotPaidUser: (browser) ->

    buttonSelector = '.more-form .alwayson'
    vmSelector     = 'a[href="/IDE/koding-vm-1/my-workspace"]'

    helpers.beginTest(browser)

    browser.element 'css selector', vmSelector, (result) =>
      if result.status is 0
        browser.end()
      else
        helpers.waitForVMRunning(browser)
        environmentHelpers.openVmSettingsModal(browser)
        environmentHelpers.clickMoreButtonInVMSettingsModal(browser)

        browser
          .waitForElementVisible  buttonSelector, 20000
          .click                  buttonSelector + ' .input-wrapper .koding-on-off a.knob'
          .pause                  2000
          .waitForElementVisible  '.kdmodal-content a.custom-link-view', 20000 # Assertion
          .end()


  # addVM: (browser) ->

  #   freeModalSelector = '.computeplan-modal.free-plan'
  #   vmSelector        = 'a[href="/IDE/koding-vm-1/my-workspace"]'

  #   helpers.beginTest(browser)
  #   helpers.waitForVMRunning(browser)

  #   browser.element 'css selector', vmSelector, (result) =>
  #     if result.status is 0
  #       browser.end()
  #     else
  #       environmentHelpers.clickAddVMButton(browser)
  #       browser.pause 5000 # wait to see the modal

  #       browser.element 'css selector', freeModalSelector, (result) =>
  #         if result.status is 0
  #           browser
  #             .waitForElementVisible   freeModalSelector, 20000
  #             .waitForElementVisible   freeModalSelector + ' a.custom-link-view span', 20000
  #             .click                   freeModalSelector + ' a.custom-link-view span'
  #
  #           helpers.selectPlan(browser)
  #           helpers.fillPaymentForm(browser)

  #           browser.url helpers.getUrl() + '/IDE'
  #           environmentHelpers.clickAddVMButton(browser)
  #           environmentHelpers.clickCreateVMButton(browser)
  #         else
  #           environmentHelpers.clickCreateVMButton(browser)


  # # this test depends addVM test.
  # turnOnNewPaidVM: (browser) ->

  #   vmName     = 'koding-vm-1'
  #   vmSelector = 'a[href="/IDE/' + vmName + '/my-workspace"]'

  #   helpers.beginTest(browser)

  #   browser
  #     .waitForElementVisible vmSelector, 25000
  #     .pause                 10000 # required, wait for IDE open.
  #     .click                 vmSelector

  #   helpers.waitForVMRunning(browser, vmName)

  #   browser.end()


  # # this test depends addVM and turnOnNewPaidVM tests.
  # makePaidVMAlwaysOn: (browser) ->

  #   helpers.beginTest(browser)

  #   environmentHelpers.openVmSettingsModal(browser, 'koding-vm-1')
  #   environmentHelpers.clickMoreButtonInVMSettingsModal(browser)

  #   browser.element  'css selector', '.more-form .alwayson .koding-on-off.on', (result) =>
  #     if result.status is 0
  #       console.log 'VM is already always on, ending test...'
  #       browser.end()

  #     else
  #       browser
  #         .waitForElementVisible    '.more-form .alwayson', 20000
  #         .click                    '.more-form .alwayson .koding-on-off'
  #         .pause                    1000
  #         .refresh()
  #         .waitForElementVisible    '[testpath=main-sidebar]', 25000, =>

  #           environmentHelpers.openVmSettingsModal(browser, 'koding-vm-1')
  #           environmentHelpers.clickMoreButtonInVMSettingsModal(browser) # Assertion

  #           browser
  #             .waitForElementVisible   '.more-form .alwayson .koding-on-off.on', 20000
  #             .end()

