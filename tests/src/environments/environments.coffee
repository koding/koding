utils   = require '../utils/utils.js'
helpers = require '../helpers/helpers.js'
faker   = require 'faker'
assert  = require 'assert'

modalSelector = '.activity-modal.vm-settings'


openVmSettingsModal = (browser, vmName) ->

  if not vmName
    vmName = 'koding-vm-0'

  vmSelector = '.activity-sidebar a[href="/IDE/' + vmName + '/my-workspace"].running'

  browser
    .waitForElementVisible   vmSelector, 20000
    .pause                   5000
    .moveToElement           vmSelector + ' span', 125, 20
    .click                   vmSelector + ' span'
    .waitForElementVisible   modalSelector, 20000 # Assertion


clickMoreButtonInVMSettingsModal = (browser) ->

  browser
    .waitForElementVisible  '.settings form.with-fields .moreview', 20000
    .click                  '.settings form.with-fields .moreview label.more'
    .pause  200


clickAddVMButton = (browser) ->

  sidebarTitle = '[testpath=main-sidebar] .activity-sidebar .vms .sidebar-title'

  browser
    .waitForElementVisible   '[testpath=main-sidebar]', 20000
    .waitForElementVisible   sidebarTitle, 20000
    .moveToElement           sidebarTitle + ' a.buy-vm', 10, 10
    .click                   sidebarTitle + ' a.buy-vm'


seeUpgradeModal = (browser) ->

  clickAddVMButton(browser)
  browser.waitForElementVisible '.computeplan-modal.free-plan .kdmodal-inner', 20000 # Assertion


addDomain = (browser) ->

  user = helpers.beginTest(browser)
  helpers.waitForVMRunning(browser)

  domainSelector    = '.more-form .domains .domains-a-hrefhttplearnkodingcomfaqvm-hostname-target-blank-span-classdomain-helpspan-a-span-classdomain-togglespan span.domain-toggle'
  paragraph         = helpers.getFakeText()
  createDomainName  = paragraph.split(' ')[0]
  domainName        = createDomainName + '.' + user.username + '.dev.koding.io'

  openVmSettingsModal(browser)

  clickMoreButtonInVMSettingsModal(browser)

  browser
    .waitForElementVisible    '.more-form .domains', 20000
    .waitForElementVisible    domainSelector, 20000
    .click                    domainSelector
    .waitForElementVisible    '.domains-view input.text', 20000
    .setValue                 '.domains-view input.text', createDomainName + '\n'
    .waitForElementVisible    '.domains-view .in-progress.kdloader', 10000
    .waitForElementNotVisible '.domains-view .in-progress.kdloader', 20000
    .assert.containsText      '.domains-view .listview-wrapper', domainName

  return domainName


clickCreateVMButton = (browser) ->

  browser
    .waitForElementVisible    '.env-modal.paid-plan', 25000
    .click                    '.env-modal.paid-plan button'
    .waitForElementVisible    'a[href="/IDE/koding-vm-1/my-workspace"]', 25000
    .end()


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


  seeUpgradeModal: (browser) ->

    helpers.beginTest(browser)
    helpers.waitForVMRunning(browser)
    seeUpgradeModal(browser)
    browser.end()


  makeAlwaysOnForNotPaidUser: (browser) ->

    buttonSelector = '.more-form .alwayson'

    helpers.beginTest(browser)
    helpers.waitForVMRunning(browser)

    openVmSettingsModal(browser)

    clickMoreButtonInVMSettingsModal(browser)

    browser
      .waitForElementVisible  buttonSelector, 20000
      .click                  buttonSelector + ' .input-wrapper .koding-on-off a.knob'
      .waitForElementVisible  '.kdmodal-content a.custom-link-view', 20000 # Assertion
      .end()


  addDomain: (browser) ->

    addDomain(browser)
    browser.end()


  deleteDomain: (browser) ->

    domainName = addDomain(browser)

    domainItem = '.domains-view .kdlistitemview-domain:last-child'
    loader     = '.domains-view .in-progress.kdloader'

    browser
      .moveToElement             domainItem, 10, 10
      .click                     domainItem + ' span.remove-domain'
      .waitForElementVisible     loader, 10000
      .waitForElementNotVisible  loader, 20000
      .getText                   domainItem, (result) =>
        assert.notEqual          result.value, domainName # Assertion

        browser.end()


  addVM: (browser) ->

    modalSelector = '.computeplan-modal.free-plan'
    pricingPage   = '.content-page.pricing'

    helpers.beginTest(browser)
    helpers.waitForVMRunning(browser)

    clickAddVMButton(browser)

    browser.pause 5000 # wait to see the modal

    browser.element 'css selector', modalSelector, (result) =>
      if result.status is 0
        console.log 'if de bu salak'
        browser
          .waitForElementVisible   modalSelector, 20000
          .waitForElementVisible   modalSelector + ' a.custom-link-view span', 20000
          .click                   modalSelector + ' a.custom-link-view span'
          .waitForElementVisible   pricingPage, 25000
          .waitForElementVisible   pricingPage + ' .plans .developer', 25000
          .pause 2000
          .click                   pricingPage + ' .plans .developer .plan-buy-button'

        helpers.fillPaymentForm(browser)

        browser.url helpers.getUrl() + '/IDE'
        clickAddVMButton(browser)
        clickCreateVMButton(browser)
      else
        console.log 'else de bu salak', result.status
        clickCreateVMButton(browser)



  # this test depends addVM test.
  turnOnNewPaidVM: (browser) ->

    vmName     = 'koding-vm-1'
    vmSelector = 'a[href="/IDE/' + vmName + '/my-workspace"]'

    helpers.beginTest(browser)

    browser
      .waitForElementVisible vmSelector, 25000
      .pause                 10000 # required, wait for IDE open.
      .click                 vmSelector

    helpers.waitForVMRunning(browser, vmName)

    browser.end()


  # this test depends addVM and turnOnNewPaidVM tests.
  makePaidVMAlwaysOn: (browser) ->

    helpers.beginTest(browser)

    openVmSettingsModal(browser, 'koding-vm-1')
    clickMoreButtonInVMSettingsModal(browser)

    browser
      .waitForElementVisible    '.more-form .alwayson', 20000
      .click                    '.more-form .alwayson .koding-on-off'
      .pause                    1000
      .refresh()
      .waitForElementVisible    '[testpath=main-sidebar]', 25000

    openVmSettingsModal(browser, 'koding-vm-1')
    clickMoreButtonInVMSettingsModal(browser)

    browser
      .waitForElementVisible   '.more-form .alwayson .koding-on-off.on', 20000
      .end()
