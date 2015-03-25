helpers = require './helpers.js'
assert  = require 'assert'


module.exports =

  openVmSettingsModal: (browser, vmName) ->

    modalSelector = '.activity-modal.vm-settings'

    if not vmName
      vmName = 'koding-vm-0'

    vmSelector = '.activity-sidebar a[href="/IDE/' + vmName + '"].running'

    browser
      .waitForElementVisible   vmSelector, 20000
      .pause                   5000
      .moveToElement           vmSelector + ' span', 125, 20
      .click                   vmSelector + ' span'
      .waitForElementVisible   modalSelector, 20000 # Assertion
      .pause                   2500


  clickMoreButtonInVMSettingsModal: (browser) ->

    browser
      .waitForElementVisible  '.settings form.with-fields .moreview', 20000
      .click                  '.settings form.with-fields .moreview'
      .pause                  2000


  clickAddVMButton: (browser) ->

    sidebarTitle = '[testpath=main-sidebar] .activity-sidebar .vms .sidebar-title'

    browser
      .waitForElementVisible   '[testpath=main-sidebar]', 20000
      .waitForElementVisible   sidebarTitle, 20000
      .moveToElement           sidebarTitle + ' a.buy-vm', 10, 10
      .click                   sidebarTitle + ' a.buy-vm'

    @clickAddKodingVMButton browser

  clickAddKodingVMButton: (browser) ->

    sidebarTitle = '[testpath=main-sidebar] .activity-sidebar .vms .sidebar-title'
    browser
      .waitForElementVisible   '.more-modal.more-vms', 20000 # Assertion
      .click                   '.kdbutton.create-koding-vm'

  seeUpgradeModal: (browser) ->

    @clickAddVMButton(browser)
    browser.waitForElementVisible '.computeplan-modal.free-plan .kdmodal-inner', 20000 # Assertion


  addDomain: (browser) ->

    user = helpers.beginTest(browser)
    helpers.waitForVMRunning(browser)

    domainSelector    = '.domains .add-domain'
    paragraph         = helpers.getFakeText()
    createDomainName  = paragraph.split(' ')[0]
    domainName        = createDomainName + '.' + user.username + '.dev.koding.io'

    @openVmSettingsModal(browser)

    @clickMoreButtonInVMSettingsModal(browser)

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


  clickCreateVMButton: (browser) ->

    browser
      .waitForElementVisible    '.env-modal.paid-plan', 25000
      .click                    '.env-modal.paid-plan button'
      .waitForElementNotVisible '.env-modal.paid-plan', 250000
      .waitForElementVisible    'a[href="/IDE/koding-vm-1"]', 25000
      .end()
