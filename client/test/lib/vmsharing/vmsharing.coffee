utils                = require '../utils/utils.js'
helpers              = require '../helpers/helpers.js'
environmentHelpers   = require '../helpers/environmenthelpers.js'
vmHelpers            = require '../helpers/vmhelpers.js'
assert               = require 'assert'


module.exports =


  before: (browser) ->

    hostBrowser = process.env.__NIGHTWATCH_ENV_KEY is 'host_1'

    if hostBrowser
      utils.getUser()

    if utils.suiteHookHasRun 'before'
    then return
    else utils.registerSuiteHook 'before'


  shareVM: (browser) ->

    host        = utils.getUser no, 0
    hostBrowser = process.env.__NIGHTWATCH_ENV_KEY is 'host_1'
    participant = utils.getUser no, 1

    vmSharingListSelector = '.vm-sharing.active'
    addUserButtonSelector = "#{vmSharingListSelector} .kdheaderview .green"
    addUserInputSelector  = '.add-view input.text'
    modalSelector         = '.computeplan-modal.free-plan .kdmodal-inner'
    userSelector          = '.listview-wrapper .kdlistitemview-user'
    sharedMachineSelector = '.activity-sidebar .shared-machines .sidebar-machine-box .vm.running'


    browser.pause 2500, -> # wait for user.json creation
      if hostBrowser
        helpers.beginTest(browser, host)
        helpers.waitForVMRunning(browser)

        environmentHelpers.openVmSharingSettings(browser)

        browser.element 'css selector', userSelector, (result) ->
          if result.status is 0
            browser.end()
          else
            vmHelpers.clickAddUserButton(browser)
            browser.pause  3000 # wait for modal

            browser.element 'css selector', modalSelector, (result) ->
              if result.status is 0
                browser
                  .click                   "#{modalSelector} a[href='/Pricing']"
                  .waitForElementVisible   '.content-page.pricing', 20000

                helpers.selectPlan(browser, 'developer')
                helpers.fillPaymentForm(browser, 'developer')
                helpers.submitForm(browser, yes)
                browser.url helpers.getUrl()

                environmentHelpers.openVmSharingSettings(browser)
                vmHelpers.clickAddUserButton(browser)

              browser
                .waitForElementVisible  addUserInputSelector, 20000
                .setValue               addUserInputSelector, participant.username
                .pause                  2000
                .element 'css selector', '.kdlistitemview-dropdown-member', (result) ->
                  if result.status is 0
                    browser
                      .click                  '.kdlistitemview-dropdown-member'
                      .pause 3000
                      .waitForElementVisible  vmSharingListSelector, 20000
                      .assert.containsText    "#{vmSharingListSelector} .listview-wrapper", participant.username
                  else
                    browser
                      .waitForElementVisible  '.kdlistview-default', 20000
                      .click                  '.kdlistview-default'
                      .setValue               addUserInputSelector, participant.username
                      .pause                  2000
                      .waitForElementVisible  '.kdlistitemview-dropdown-member', 20000
                      .click                  '.kdlistitemview-dropdown-member'
                      .pause 3000
                      .waitForElementVisible  vmSharingListSelector, 20000
                      .assert.containsText    "#{vmSharingListSelector} .listview-wrapper", participant.username

                  browser
                    .pause  5000 # wait for pariticipant finish
                    .end()
      else
        sharedMachineSelector  = '.activity-sidebar .shared-machines .sidebar-machine-box .vm.running'

        helpers.beginTest(browser, participant)

        title = "Open IDE for koding-vm-0 (shared by @#{host.username})"

        browser.element 'css selector', "a[title='#{title}']", (result) ->

          if result.status is 0
            console.log ',,,,,,,,,,,,,'
            browser
              .pause 7000 # wait for host to end
              .end()
          else
            browser.waitForElementPresent  sharedMachineSelector, 600000
            vmHelpers.acceptInvitation(browser, host, participant)
            browser.pause 5000
            browser.end()