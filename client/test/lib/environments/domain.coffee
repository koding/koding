helpers = require '../helpers/helpers.js'
assert  = require 'assert'
environmentHelpers = require '../helpers/environmenthelpers.js'

domainItem  = '.domains-view .kdlistitemview-domain:last-child'
loader      = '.domains-view .in-progress.kdloader'

module.exports =


  # openVmDomain: (browser) ->

  #   modalSelector = '.activity-modal.vm-settings'
  #   linkSelector  = modalSelector + ' .assigned-url .custom-link-view'

  #   helpers.beginTest(browser)
  #   helpers.waitForVMRunning(browser)

  #   environmentHelpers.openVmSettingsModal(browser)

  #   browser
  #     .waitForElementVisible   linkSelector, 20000
  #     .getAttribute            linkSelector, 'href', (result) ->
  #       domain = result.value

  #       browser
  #         .url domain
  #         .pause  5000
  #         .waitForElementVisible  '#container', 20000
  #         .waitForElementVisible  '#container .hellobox', 20000
  #         .end()


  addDomain: (browser) ->

    environmentHelpers.addDomain(browser)
    browser.end()


  deleteDomain: (browser) ->

    domainName = environmentHelpers.addDomain(browser)

    browser
      .moveToElement             domainItem, 10, 10
      .click                     domainItem + ' span.remove'
      .waitForElementVisible     loader, 10000
      .waitForElementNotVisible  loader, 20000
      .getText                   domainItem, (result) =>
        assert.notEqual          result.value, domainName # Assertion

        browser.end()


  assignDomain: (browser) ->

    domainName = environmentHelpers.addDomain(browser)

    browser
      .waitForElementVisible     domainItem, 20000
      .click                     domainItem + ' .koding-on-off.on'
      .waitForElementVisible     loader, 10000
      .waitForElementNotVisible  loader, 20000
      .refresh()

    environmentHelpers.openVmSettingsModal(browser)
    environmentHelpers.clickMoreButtonInVMSettingsModal(browser)

    browser
      .waitForElementVisible     domainItem + ' .koding-on-off.off', 20000
      .end()
