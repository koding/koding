assert   = require 'assert'
helpers  = require '../helpers/helpers.js'

environmentHelpers = require '../helpers/environmenthelpers.js'
helpers            = require '../helpers/helpers.js'


module.exports =

  acceptOrRejectInvitation: (browser, firstUser, secondUser, accept) ->

    firstUserName    = firstUser.username
    shareModal       = '.share-modal'
    fullName         = shareModal + ' .user-details .fullname'
    acceptButton     = shareModal + ' .kdbutton.green'
    rejectButton     = shareModal + ' .kdbutton.red'
    selectedMachine  = '.shared-machines .sidebar-machine-box'
    openMachine      = "#{selectedMachine} .running"

    browser
      .waitForElementVisible     shareModal, 500000 # wait for vm turn on for host
      .waitForElementVisible     fullName, 50000
      .assert.containsText       shareModal, firstUserName

    if accept
      browser
        .waitForElementVisible   acceptButton, 50000
        .click                   acceptButton
    else
      browser
        .waitForElementVisible   rejectButton, 50000
        .click                   rejectButton

    browser
      .waitForElementNotPresent  shareModal, 50000
      .pause                     3000 # wait for sidebar redraw

    if accept
      browser.waitForElementVisible     openMachine, 20000 # Assertion
    else
      browser.waitForElementNotPresent  selectedMachine, 20000 # Assertion


  clickAddUserButton: (browser) ->

    vmSharingListSelector = '.vm-sharing.active'
    addUserButtonSelector = "#{vmSharingListSelector} .kdheaderview .green"

    browser
      .waitForElementVisible  vmSharingListSelector, 20000
      .waitForElementVisible  addUserButtonSelector, 20000
      .click                  addUserButtonSelector


  upgradePlanForVMSharing: (browser) ->

    modalSelector = '.computeplan-modal.free-plan .kdmodal-inner'

    browser
      .click                   "#{modalSelector} a[href='/Pricing']"
      .waitForElementVisible   '.content-page.pricing', 20000

    helpers.selectPlan(browser, 'developer')
    helpers.fillPaymentForm(browser, 'developer')
    helpers.submitForm(browser, yes)
    browser.url helpers.getUrl()

    environmentHelpers.openVmSharingSettings(browser)
    @clickAddUserButton(browser)


  inviteUser: (browser, participant, callback) ->

    addUserInputSelector  = '.add-view input.text'

    browser
      .waitForElementVisible   addUserInputSelector, 20000
      .setValue                addUserInputSelector, participant.username
      .pause                   2000
      .element 'css selector', '.kdlistitemview-dropdown-member', (result) ->
        if result.status is 0
          browser
            .click '.kdlistitemview-dropdown-member'
            .pause 3000
            callback()
        else
          browser
            .waitForElementVisible  '.kdlistview-default', 20000
            .click                  '.kdlistview-default'
            .setValue               addUserInputSelector, participant.username
            .pause                  2000
            .waitForElementVisible  '.kdlistitemview-dropdown-member', 20000
            .click                  '.kdlistitemview-dropdown-member'
            .pause 3000
            callback()


  handleInvitation: (browser, host, participant, accept, endSessionAfterAcceptingInvite = yes) ->

    sharedMachineSelector = '.activity-sidebar .shared-machines .sidebar-machine-box .vm.running'
    newTerminalButton     = '.kdsplitview-horizontal .panel-1 .kdtabhandlecontainer .kdtabhandle-tabs .visible-tab-handle'
    newTerminalLink       = '.kdcontextmenu .context-list-wrapper .new-terminal'
    sessionLink           = '.kdlistview-contextmenu ul:nth-of-type(1) .has-sub-items'
    openNewTerminal       = '.kdlistview-contextmenu.default .open'
    sharedVmSelector      = '.activity-sidebar .machines-wrapper section:nth-of-type(2) .vm.koding'
    sharedVMSettings      = '.activity-sidebar .machines-wrapper section:nth-of-type(2) .vm.koding .settings-icon'
    leaveSharedVM         = '.kdmodal-content button'


    helpers.beginTest(browser, participant)

    title = "Open IDE for koding-vm-0 (shared by @#{host.username})"

    browser.element 'css selector', "a[title='#{title}']", (result) =>

      if result.status is 0
        browser
          .pause 7000 # wait for host to end
          .end()
      else
        browser.waitForElementPresent  sharedMachineSelector, 600000
        @acceptOrRejectInvitation(browser, host, participant, accept)

        browser.pause 5000

        if endSessionAfterAcceptingInvite
          browser.end()
        else
          browser
            .waitForElementVisible   newTerminalButton, 20000
            .click                   newTerminalButton
            .waitForElementVisible   newTerminalLink, 20000
            .moveToElement           newTerminalLink, 5, 5
            .waitForElementVisible   sessionLink, 20000
            .moveToElement           sessionLink, 5, 5
            .waitForElementVisible   openNewTerminal, 20000
            .click                   openNewTerminal
            .pause                   2500 #wait for terminal to be displayed
            .execute                 "window._kd.singletons.appManager.frontApp.ideViews.last.tabView.activePane.view.webtermView.terminal.server.input('ls')"
            .execute                 "window._kd.singletons.appManager.frontApp.ideViews.last.tabView.activePane.view.webtermView.terminal.keyDown({type: 'keydown', keyCode: 13, stopPropagation: function() {}, preventDefault: function() {}});"
            .pause                   5000
            .end()


  handleInvite: (browser, host, participant, callback) ->

    modalSelector         = '.computeplan-modal.free-plan .kdmodal-inner'
    userSelector          = '.listview-wrapper .kdlistitemview-user'
    sharedMachineSelector = '.activity-sidebar .shared-machines .sidebar-machine-box .vm.running'

    helpers.beginTest(browser, host)
    helpers.waitForVMRunning(browser)

    environmentHelpers.openVmSharingSettings(browser)

    browser.pause 5000 # wait for user list
    browser.element 'css selector', userSelector, (result) =>
      if result.status is 0
        @removeAllInvitations(browser)

      @clickAddUserButton(browser)
      browser.pause  3000 # wait for modal

      browser.element 'css selector', modalSelector, (result) =>
        if result.status is 0
          @upgradePlanForVMSharing(browser)

        @inviteUser browser, participant, callback


  removeAllInvitations: (browser) ->

    userItemSelector = '.listview-wrapper .kdlistitemview-user'
    firstUserItem    = "#{userItemSelector}:first-child"
    removeButton     = "#{firstUserItem} .remove"

    doClose = ->
      browser
        .moveToElement firstUserItem, 15, 15
        .click         removeButton
        .pause         2000


    close = ->
      browser.elements 'css selector', userItemSelector, (result) ->
        length = result.value.length

        if result.value.length isnt 0 then doClose()
        if length - 1 > 0 then close()

    close()
