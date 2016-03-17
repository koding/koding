helpers = require '../helpers/helpers.js'
environmentHelpers = require '../helpers/environmenthelpers.js'

vmSelector = '.sidebar-machine-box.koding-vm-1'


module.exports =


  addVM: (browser) ->

    freeModalSelector = '.computeplan-modal.free-plan'
    linkSelector      = "#{freeModalSelector} a.custom-link-view span"

    helpers.beginTest(browser)
    helpers.waitForVMRunning(browser)

    browser.element 'css selector', vmSelector, (result) ->
      if result.status is 0
        browser.end()
      else
        environmentHelpers.clickAddVMButton(browser)
        browser.pause 10000 # wait to see the modal

        browser.element 'css selector', freeModalSelector, (result) ->
          if result.status is 0
            browser
              .waitForElementVisible   linkSelector, 20000
              .click                   linkSelector

            helpers.selectPlan(browser)
            helpers.fillPaymentForm(browser)
            helpers.submitForm(browser, yes)

            browser
              .url helpers.getUrl() + '/IDE'
              .pause  10000 # wait for sidebar redraw

            environmentHelpers.clickAddVMButton(browser)
            environmentHelpers.clickCreateVMButton(browser)
          else
            environmentHelpers.clickCreateVMButton(browser)

          browser.end()


  # this test depends addVM test.
  turnOnNewPaidVM: (browser) ->

    vmName = 'koding-vm-1'

    helpers.beginTest(browser)
    browser.pause  5000 # wait for load koding-vm-1

    browser.element 'css selector', "#{vmSelector} .running", (result) ->
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

    browser.element  'css selector', '.AppModal-form.with-fields .alwayson .koding-on-off.on', (result) ->
      if result.status is 0
        console.log ' ✔ VM is already always on, ending test...'
        browser.end()

      else
        browser
          .waitForElementVisible    '.AppModal-form.with-fields .alwayson', 20000
          .click                    '.AppModal-form.with-fields .alwayson .koding-on-off'
          .pause                    1000
          .refresh()
          .waitForElementVisible    '[testpath=main-sidebar]', 25000, ->

            environmentHelpers.openVmSettingsModal(browser, 'koding-vm-1')

            browser
              .waitForElementVisible   '.AppModal-form.with-fields .alwayson .koding-on-off.on', 20000
              .end()
