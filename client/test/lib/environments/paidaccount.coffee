helpers = require '../helpers/helpers.js'
assert  = require 'assert'
environmentHelpers = require '../helpers/environmenthelpers.js'

vmSelector = '.sidebar-machine-box.koding-vm-1'


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


  addVM: (browser) ->

    freeModalSelector = '.computeplan-modal.free-plan'

    helpers.beginTest(browser)
    helpers.waitForVMRunning(browser)

    browser.element 'css selector', vmSelector, (result) =>
      if result.status is 0
        browser.end()
      else
        environmentHelpers.clickAddVMButton(browser)
        browser.pause 5000 # wait to see the modal

        browser.element 'css selector', freeModalSelector, (result) =>
          if result.status is 0
            browser
              .waitForElementVisible   freeModalSelector, 20000
              .waitForElementVisible   freeModalSelector + ' a.custom-link-view span', 20000
              .click                   freeModalSelector + ' a.custom-link-view span'

            helpers.selectPlan(browser)
            helpers.fillPaymentForm(browser)

            browser.url helpers.getUrl() + '/IDE'
            environmentHelpers.clickAddVMButton(browser)
            environmentHelpers.clickCreateVMButton(browser)
          else
            environmentHelpers.clickCreateVMButton(browser)


  # this test depends addVM test.
  turnOnNewPaidVM: (browser) ->

    vmName     = 'koding-vm-1'

    helpers.beginTest(browser)

    browser.element 'css selector', "#{vmSelector} .running", (result) =>
      if result.status is 0
        browser.end()
      else
        browser
          .waitForElementVisible vmSelector, 25000
          .pause                 10000 # required, wait for IDE open.
          .click                 vmSelector

        helpers.waitForVMRunning(browser, vmName)

        browser.end()


  # this test depends addVM and turnOnNewPaidVM tests.
  makePaidVMAlwaysOn: (browser) ->

    helpers.beginTest(browser)

    environmentHelpers.openVmSettingsModal(browser, 'koding-vm-1')

    browser.element  'css selector', '.AppModal-form.with-fields .alwayson .koding-on-off.on', (result) =>
      if result.status is 0
        console.log 'VM is already always on, ending test...'
        browser.end()

      else
        browser
          .waitForElementVisible    '.AppModal-form.with-fields .alwayson', 20000
          .click                    '.AppModal-form.with-fields .alwayson .koding-on-off'
          .pause                    1000
          .refresh()
          .waitForElementVisible    '[testpath=main-sidebar]', 25000, =>

            environmentHelpers.openVmSettingsModal(browser, 'koding-vm-1')

            browser
              .waitForElementVisible   '.AppModal-form.with-fields .alwayson .koding-on-off.on', 20000
              .end()
