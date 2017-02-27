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
      .pause   5000 # wait for sidebar redraw
      .element 'css selector', modalSelector, (result) ->
        if result.status is 0
          browser
            .waitForElementVisible   itemSelector, 20000
            .click                   itemSelector
        else
          browser
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


  openGeneralSettings: (browser, vmName) ->

    @openVmSettingsModal browser, vmName


  openDomainSettings: (browser, vmName) ->

    @openVmSettingsModal browser, vmName, '.domains'


  openAdvancedSettings: (browser, vmName) ->

    @openVmSettingsModal browser, vmName, '.advanced'


  openVmSharingSettings :(browser, vmName) ->

    @openVmSettingsModal browser, vmName, '.vm-sharing'


  clickAddVMButton: (browser) ->

    sidebarTitle = '[testpath=main-sidebar] .activity-sidebar .my-machines .sidebar-title'

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
    createDomainName     = "#{paragraph.split(' ')[0]}#{Date.now()}"
    domainName           = createDomainName + '.' + user.username + '.dev.koding.io'

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
      .getText                   domainSelector, (result) ->
        assert.notEqual          result.value, domainName # Assertion


  clickCreateVMButton: (browser) ->

    browser
      .waitForElementVisible    '.env-modal.paid-plan', 50000
      .click                    '.env-modal.paid-plan button'
      .waitForElementNotVisible '.env-modal.paid-plan', 50000
      .pause                    5000 # wait for action complete
      .waitForElementVisible    '.my-machines .sidebar-machine-box.koding-vm-1', 50000


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


  terminateVM: (browser) ->

    terminateSelector       = '.kdmodal.AppModal .advanced .advanced.terminate'
    proceedSelector         = '.kdmodal.with-buttons .kdbutton.red'
    terminatedLabelSelector = '.kdmodal.env-modal .state-label.terminated'
    vmSelector              = '.sidebar-machine-box'
    vmStateModal            = '.env-machine-state .kdmodal-content'

    browser
      .waitForElementVisible  terminateSelector, 20000
      .click                  terminateSelector
      .waitForElementVisible  proceedSelector, 20000
      .click                  proceedSelector
      .waitForElementVisible  vmSelector   + ' .vm.terminating', 200000
      .waitForElementVisible  vmStateModal + ' .terminating', 20000
      .waitForElementVisible  terminatedLabelSelector, 200000
      .assert.containsText    terminatedLabelSelector, 'successfully deleted' #Assertion


  createNewVMForNonPayingUsers: (browser) ->

    createVMbutton    = '.content-container .kdbutton'
    addKodingVmButton = '.environments-modal .kdbutton.add-vm-button'
    vmSelector        = '.sidebar-machine-box'
    vmStateModal      = '.env-machine-state .kdmodal-content'

    browser
      .waitForElementVisible  createVMbutton, 20000
      .click                  createVMbutton
      .waitForElementVisible  addKodingVmButton, 20000
      .click                  addKodingVmButton
      .waitForElementVisible  vmSelector, 20000
      .assert.containsText    vmSelector, 'koding-vm-0'
      .pause                   2500 # wait for correct pop-up to appear
      .waitForElementVisible  vmStateModal + ' .turn-on', 50000
      .assert.containsText    vmStateModal + ' .turn-on', 'TURN IT ON'


  createNewVmForHobbyistPlan: (browser) ->

    vmSelector    = '.machines-wrapper .buy-vm'
    createVmModal = '.kdmodal-inner .kdmodal-content .message'
    addVmSelector = '.footer .button-container .add-vm-button'

    browser
      .moveToElement           '.sidebar-machine-box', 10, 10
      .waitForElementVisible   vmSelector, 20000
      .click                   vmSelector
      .waitForElementVisible   addVmSelector, 20000
      .click                   addVmSelector
      .waitForElementVisible   createVmModal, 20000
      .assert.containsText     createVmModal, 'Hobbyist plan is restricted to only one VM.'
      .assert.containsText     '.kdmodal-inner .kdmodal-content .custom-link-view span', 'Upgrade your account for more VMs RAM and Storage'


  addNewVM: (browser, vmAssert, addNewVmNotAllowed = no, remainingSlots, usedStorage) ->

    sidebarSelector        = '.kdview.sidebar-machine-box .vm'
    addVmSelector          = '.sidebar-title .custom-link-view.add-icon.buy-vm'
    addVmButton            = '.button-container .add-vm-button'
    disabledCreateVmButton = '.computeplan-modal .kdbutton.solid'

    browser
      .pause                  2000 #wait for the new vm to be displayed
      .waitForElementVisible  sidebarSelector, 20000
      .moveToElement          sidebarSelector, 10, 10
      .waitForElementVisible  addVmSelector, 20000
      .click                  addVmSelector
      .waitForElementVisible  addVmButton, 20000
      .click                  addVmButton

    if addNewVmNotAllowed
      browser
        .waitForElementVisible  '.computeplan-modal [disabled="disabled"]', 20000
        .assert.containsText    '.kdmodal-content .kdview.modal-title.warn', remainingSlots
        .assert.containsText    vmAssert, usedStorage
    else
      browser
        .waitForElementVisible  disabledCreateVmButton, 20000
        .click                  disabledCreateVmButton
        .pause                  2000 #for page to finish loading
        .waitForElementVisible  vmAssert, 20000


  setAlwaysOnVm: (browser, secondVM = no) ->

    sidebarSelector  = '.kdview.sidebar-machine-box .vm'
    vmSelector       = '.activity-sidebar .machines-wrapper .vms.my-machines .koding-vm-'
    vmSelector1      = "#{vmSelector}1"
    closeModalButton = '.kdmodal-inner .close-icon'

    @checkAlwaysOnVM(browser)

    browser
      .click                  closeModalButton
      .waitForElementVisible  sidebarSelector, 20000

    if secondVM
      @addNewVM(browser, vmSelector1)
      @checkAlwaysOnVM(browser, yes)


  simplifiedSubmitForm: (browser) ->
    browser
      .waitForElementVisible   'button.submit-btn', 20000
      .click                   'button.submit-btn'
      .waitForElementVisible   '.kdmodal-content .success-msg', 20000
      .click                   'button.submit-btn'
      .waitForElementVisible   '[testpath=main-sidebar]', 20000


  checkAlwaysOnVM: (browser, secondVM = no) ->

    alwaysOnSelector = '.kdinput.koding-on-off.statustoggle.small'
    sidebarSelector  = '.kdview.sidebar-machine-box .vm'
    settingsSelector = '.kdview.sidebar-machine-box.koding-vm-1 .vm .settings-icon'
    vmSelector       = '.activity-sidebar .machines-wrapper .vms.my-machines .koding-vm-'
    vmSelector1      = "#{vmSelector}1"

    if secondVM
      browser
        .waitForElementVisible  vmSelector1, 20000
        .moveToElement          vmSelector1, 10, 10
        .pause                  2500 # for the selector to load
        .waitForElementVisible  settingsSelector, 20000
        .click                  settingsSelector

    else
      browser
        .pause                  2500 # for the page to load
        .waitForElementVisible  sidebarSelector, 20000
        .moveToElement          sidebarSelector, 10, 10
        .waitForElementVisible  "#{sidebarSelector} span.settings-icon", 20000
        .click                  "#{sidebarSelector} span.settings-icon"

    browser
      .waitForElementVisible  "#{alwaysOnSelector}.off", 20000
      .element 'css selector', "#{alwaysOnSelector}.off", (result) ->
        if result.status is 0
          browser
            .click                  "#{alwaysOnSelector}.off"
            .waitForElementVisible  "#{alwaysOnSelector}.on", 20000
