helpers = require './helpers.js'
assert  = require 'assert'

modalSelector = '.machine-settings-modal.AppModal'

module.exports =


  openVmSettingsModal: (browser, vmName, cssSelector) ->

    if not vmName
      vmName = 'koding-vm-0'

    if not cssSelector
      cssSelector = '.general'

    modalSelector = '.machine-settings-modal.AppModal'
    itemSelector  = modalSelector + ' .AppModal-navItem' + cssSelector
    vmSelector    = ".activity-sidebar .sidebar-machine-box.#{vmName} .running"

    browser
      .pause                   5000 # wait for sidebar redraw
      .waitForElementVisible   vmSelector, 20000
      .moveToElement           vmSelector + ' span', 125, 20
      .click                   vmSelector + ' span'
      .waitForElementVisible   modalSelector, 20000 # Assertion
      .pause                   2500
      .waitForElementVisible   itemSelector, 20000
      .click                   itemSelector


  openDiskUsageSettings: (browser, vmName) ->

    @openVmSettingsModal browser, vmName, '.disk-usage'


  openSpecsSettings: (browser, vmName) ->

    @openVmSettingsModal browser, vmName, '.specs'


  openGeneralSettings: (browser,vmName) ->

    @openVmSettingsModal browser, vmName


  openDomainSettings: (browser, vmName) ->

    @openVmSettingsModal browser, vmName, '.domains'


  openAdvancedSettings: (browser, vmName) ->

    @openVmSettingsModal browser, vmName, '.advanced'


  openSnapshotsSettings: (browser,vmName) ->


    @openVmSettingsModal browser, vmName, '.snapshots'


  attemptCreateSnapshot: (browser, openSettings = yes) ->

    buttonSelector   = '.snapshots .add-button'

    if openSettings
      @openSnapshotsSettings(browser)

    browser
      .waitForElementVisible buttonSelector, 20000
      .click                 buttonSelector


  addSnapsButton: (browser) ->

    buttonSelector   = '.snapshots .add-button'

    browser
      .waitForElementVisible buttonSelector, 20000
      .click                 buttonSelector


  renameSnapshot: (browser) ->

    name                  = 'renamed-snapshot'
    inputSelector         = '.snapshots input[type=text].label'
    snapshotSelector      = '.snapshots .kdlistitemview-snapshot:first-child'
    renameButtonSelector  = '.snapshots .info .buttons button.rename'

    browser
      .waitForElementVisible snapshotSelector, 20000
      .moveToElement         snapshotSelector, 200, 20
      .waitForElementVisible renameButtonSelector, 20000
      .click                 renameButtonSelector
      .waitForElementVisible inputSelector, 20000
      .clearValue            inputSelector
      .setValue              inputSelector, [name, browser.Keys.RETURN]

    return name


  nameSnapshot: (browser) ->

    name            = helpers.getFakeText().split(' ')[0]
    inputSelector   = '.snapshots .text.hitenterview'

    browser
      .waitForElementVisible inputSelector, 20000
      .click                 inputSelector
      .setValue              inputSelector, [name, browser.Keys.RETURN]

    return name


  createSnapshot: (browser, openSettings = yes) ->

    upgradeSelector  = '.kdmodal.computeplan-modal .custom-link-view'
    labelSelector    = '.kdlistitemview-snapshot .info .label'
    snapshotSelector = '.snapshots .kdlistitemview-snapshot:first-child'

    if openSettings
      @attemptCreateSnapshot(browser)

    browser.element 'css selector',snapshotSelector , (result) =>
      if result.status is 0
        console.log '✔ Snapshot exits. Ending test...'
      else
        browser.pause 3000 #Wait for the modal for upgrading to be displayed or not

        browser.element 'css selector', upgradeSelector, (result) =>

          if result.status is 0 # upgrade account then create snapshot
            browser.click(upgradeSelector)
            helpers.selectPlan(browser)
            helpers.fillPaymentForm(browser)
            browser.url helpers.getUrl() + '/IDE'
            @attemptCreateSnapshot(browser)

          name = @nameSnapshot(browser)

          browser
            .waitForElementVisible labelSelector, 300000
            .assert.containsText   labelSelector, name #Assertion


  assertSnapshotPresent: (browser, name, reverse=false) ->

    listSelector = ".snapshots .kdlistview"

    browser.elements 'css selector', listSelector+" .kdlistitemview-snapshot.snapshot .label", (elements) ->
      elements.value.map (value) ->
        browser.elementIdText value.ELEMENT, (res) ->
          if name is res
            if reverse
              assert.notEqual res,name, "Snapshot present when not expected to be"
            else
              assert.equal res,name


  createSnapshotIfNotFound: (browser, callback) ->

    browser.element 'css selector', ".kdlistview .kdlistitemview-snapshot", (result) ->
      name = null
      if result.status is not 0
        name = environmentHelpers.createSnapshot(browser)

      callback(name)


  deleteSnapshot: (browser) ->

    elementSelector = ".kdlistview .kdlistitemview-snapshot.snapshot:first-child"
    deleteSelector  = "#{elementSelector} .buttons .delete"
    confirmSelector = ".kdmodal .kdmodal-buttons .red"

    browser
      .waitForElementVisible elementSelector, 20000
      .moveToElement         elementSelector, 205, 22
      .waitForElementVisible deleteSelector, 20000
      .click                 deleteSelector
      .waitForElementVisible confirmSelector, 20000
      .click                 confirmSelector


  openResizeVmModal: (browser) ->

    resizeSelector  = ".disk-usage-info .footline .resize"

    @openDiskUsageSettings(browser)

    browser
      .waitForElementVisible resizeSelector, 20000
      .click                 resizeSelector


  clickAddVMButton: (browser) ->

    sidebarTitle = '[testpath=main-sidebar] .activity-sidebar .vms .sidebar-title'

    browser
      .waitForElementVisible   '[testpath=main-sidebar]', 20000
      .waitForElementVisible   sidebarTitle, 20000
      .moveToElement           sidebarTitle + ' a.buy-vm', 10, 10
      .click                   sidebarTitle + ' a.buy-vm'

    @clickAddKodingVMButton browser


  clickAddKodingVMButton: (browser) ->

    modalSelector  = '.environments-modal'
    itemSelector   = "#{modalSelector} .machines-item:not(.header)"
    buttonSelector = "#{modalSelector} .kdbutton.add-vm-button"

    browser
      .waitForElementVisible   modalSelector,  50000 # Assertion
      .waitForElementVisible   itemSelector,   50000 # Assertion
      .waitForElementVisible   buttonSelector, 50000 # Assertion
      .click                   buttonSelector


  seeUpgradeModal: (browser) ->

    @clickAddVMButton(browser)
    browser.waitForElementVisible '.computeplan-modal.free-plan .kdmodal-inner', 20000 # Assertion


  addDomain: (browser, user) ->

    buttonSelector       = '.domains .kdheaderview button.add-button'
    buttonLoaderSelector = '.add-view button.loading'
    paragraph            = helpers.getFakeText()
    createDomainName     = paragraph.split(' ')[0]
    domainName           = createDomainName + '.' + user.username + '.dev.koding.io'

    @openDomainSettings(browser)

    browser
      .waitForElementVisible    buttonSelector, 20000
      .click                    buttonSelector
      .waitForElementVisible    '.add-view input.hitenterview', 20000
      .setValue                 '.add-view input.hitenterview', createDomainName + '\n'
      .waitForElementVisible    buttonLoaderSelector, 10000
      .waitForElementNotVisible buttonLoaderSelector, 20000
      .assert.containsText      '.kdlistitemview-domain:last-child' , domainName

    return domainName


  deleteDomain: (browser, user, domainName) ->

    domainSelector = '.machine-settings-modal .kdlistitemview-domain'
    lastDomainItem = "#{domainSelector}:last-child"
    loader         = lastDomainItem + '.in-progress'

    browser
      .moveToElement             lastDomainItem, 10, 10
      .click                     lastDomainItem + ' span.remove'
      .waitForElementVisible     loader, 10000
      .waitForElementNotVisible  loader, 20000
      .getText                   domainSelector, (result) =>
        assert.notEqual          result.value, domainName # Assertion


  clickCreateVMButton: (browser) ->

    browser
      .waitForElementVisible    '.env-modal.paid-plan', 50000
      .click                    '.env-modal.paid-plan button'
      .waitForElementNotVisible '.env-modal.paid-plan', 50000
      .waitForElementVisible    '.my-machines .koding-vm-1 a:first-child', 50000


  nameVM: (browser, name) ->

    vmModal       = modalSelector + ' .AppModal-form'
    nicknameInput = vmModal + ' .nickname input[name=nickEdit]'

    browser
      .waitForElementVisible  vmModal, 20000
      .waitForElementVisible  vmModal + ' .nickname', 20000
      .click                  vmModal + ' .nickname .edit'
      .waitForElementVisible  nicknameInput, 20000
      .clearValue             nicknameInput
      .setValue               nicknameInput, name + '\n'
