utils   = require '../utils/utils.js'
helpers = require '../helpers/helpers.js'
faker   = require 'faker'
assert  = require 'assert'

modalSelector = '.activity-modal.vm-settings'


openVmSettingsModal = (browser) ->

    vmSelector = '.activity-sidebar a.running'

    browser
      .waitForElementVisible   vmSelector, 20000
      .pause                   5000
      .moveToElement           vmSelector + ' span', 125, 20
      .click                   vmSelector + ' span'
      .waitForElementVisible   modalSelector, 20000


module.exports =


  openVmDomain: (browser) ->

    linkSelector = modalSelector + ' .assigned-url .custom-link-view'

    helpers.beginTest(browser)
    helpers.waitForVMRunning(browser)

    openVmSettingsModal(browser)

    browser
      .waitForElementVisible   linkSelector, 20000
      .getAttribute            linkSelector, 'href', (result) ->
        domain = result.value

        browser
          .url domain
          .waitForElementVisible  '#container', 20000
          .waitForElementVisible  '#container .hellobox', 20000
          .end()


  turnOffVm: (browser) ->

    linkSelector = modalSelector + ' .statustoggle .input-wrapper'

    helpers.beginTest(browser)
    helpers.waitForVMRunning(browser)

    openVmSettingsModal(browser)

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

