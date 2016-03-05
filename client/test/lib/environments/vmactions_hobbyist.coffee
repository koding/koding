environmentHelpers = require '../helpers/environmenthelpers.js'
helpers = require '../helpers/helpers.js'
assert  = require 'assert'

hobbyistPlanSelector = '.single-plan.hobbyist.current'
vmSelector           = '.sidebar-machine-box.koding-vm-1'
url                  = helpers.getUrl()
planType             = 'hobbyist'

module.exports =

  before: (browser) ->

    helpers.beginTest(browser)

    browser.url helpers.getUrl() + '/Pricing'

    browser.element 'css selector', hobbyistPlanSelector, (result) ->
      if result.status is -1
        helpers.selectPlan(browser, 'hobbyist')
        helpers.fillPaymentForm(browser, 'hobbyist')
        environmentHelpers.simplifiedSubmitForm(browser)
      else
      	browser.url url


  createNewVmForHobbyistPlan: (browser) ->

    hobbyistPlanSelector = '.single-plan.hobbyist.current'

    environmentHelpers.createNewVmForHobbyistPlan(browser)
    browser.end()


  checkAlwaysOnVmForHobbyistPlan: (browser) ->

    environmentHelpers.checkAlwaysOnVM(browser)
    browser.end()


  checkIncreasedDiskSizeUntilLimit: (browser) ->

    resizeDiskLink      = '.disk-usage-info .footline .resize'
    resizeVmButton      = '.kdmodal-content .container .solid.medium.green'
    confirmResizeButton = '.kddraggable.with-buttons .kdmodal-buttons .solid.red'
    contentVmSelector   = '.content-container .state-label.'
    vmSidebarSelector   = '.activity-sidebar .machines-wrapper .vms.my-machines .koding.running'
    diskUsageSelector   = '.disk-usage-info .usage-info span'

    browser.element 'css selector', vmSelector, (result) =>
      if result.status is 0
        browser.end()
      else
        helpers.waitForVMRunning(browser)
        environmentHelpers.openVmSettingsModal(browser)
        environmentHelpers.openDiskUsageSettings(browser)

    browser
      .waitForElementVisible  diskUsageSelector, 20000
      .assert.containsText    diskUsageSelector, 'of 2.'
      .click				  resizeDiskLink
      .waitForElementVisible  '.kdmodal-content .storage-container .sliderbar-container', 20000
      .click                  '.kdmodal-content .storage-container .sliderbar-container [style="left: 47.0588%;"]'
      .waitForElementVisible  '.kdmodal-content .container [disabled="disabled"]', 20000
      .click                  '.kdmodal-content .storage-container .sliderbar-container [style="left: 41.1765%;"]'
      .waitForElementVisible  resizeVmButton, 20000
      .click                  resizeVmButton
      .waitForElementVisible  confirmResizeButton, 20000
      .click                  confirmResizeButton
      .waitForElementVisible  "#{contentVmSelector}pending", 35000
      .waitForElementVisible  "#{contentVmSelector}stopping", 35000
      .waitForElementVisible  "#{contentVmSelector}pending", 350000
      .waitForElementVisible  "#{contentVmSelector}starting", 350000
      .waitForElementVisible  vmSidebarSelector, 350000

    environmentHelpers.openVmSettingsModal(browser)
    environmentHelpers.openDiskUsageSettings(browser)

    browser
      .waitForElementVisible  diskUsageSelector, 20000
      .assert.containsText    diskUsageSelector, 'of 9.'
      .end()
