assert = require 'assert'
helpers = require '../helpers/helpers.js'
async = require 'async'
helpers = require '../helpers/helpers.js'
utils = require '../utils/utils.js'
ideHelpers = require '../helpers/idehelpers.js'
environmentHelpers = require '../helpers/environmenthelpers.js'
teamsHelpers = require '../helpers/teamshelpers.js'
collaborationHelpers = require '../helpers/collaborationhelpers.js'
terminalHelpers = require '../helpers/terminalhelpers.js'
virtualMachinesUrl = "#{helpers.getUrl(yes)}/Home/stacks/virtual-machines"
machineSharingDetails = '.MachineSharingDetails'
inputSelector = "#{machineSharingDetails} input.kdinput.text"
memberSelector = "#{machineSharingDetails} .AutocompleteListItem"
membersList = "#{machineSharingDetails} .UserList"
sharedUserlist = "#{machineSharingDetails} .UserList"
noFoundUserList = "#{machineSharingDetails} .NoItem"
addAConnectedMachineButtonSelector = '.kdbutton.GenericButton.HomeAppViewVMSection--addOwnMachineButton'
machineDetailSelector = '.MachinesListItem-machineDetails'
vmSharingSelector = "#{machineDetailSelector} .MachineDetails div.GenericToggler:nth-of-type(4)"
vmSharingToggleSelector = "#{vmSharingSelector} .react-toggle-thumb"
virtualMachineSelector  = '.HomeAppView--section.virtual-machines'
runningVMSelector = "#{virtualMachineSelector} .MachinesListItem-machineLabel.Running"
sharedMachineSelector = '.SidebarMachinesListItem.Running'
sidebarPopover = '.Popover-Wrapper'
acceptSharedMachine = "#{sidebarPopover} .kdbutton.solid.green.medium"
rejectSharedMachine = "#{sidebarPopover} .kdbutton.solid.red.medium"
closeModal = '.close-icon.closeModal'
fullName = '.SidebarWidget-FullName'
leaveSessionButton = '.SidebarWidget .kdbutton.solid.red'
proceedButton = '[testpath=proceed]'
sharedMachineButtonSettings = '.MachineSettings'
removeSharedMachineMember = "#{membersList} .remove"
url = helpers.getUrl(yes)
activeTerminal = '.kdtabpaneview.terminal.active'
insertCommand  = 'window._kd.singletons.appManager.frontApp.ideViews.last.tabView.activePane.view.webtermView.terminal.server.input'
executeCommand = "window._kd.singletons.appManager.frontApp.ideViews.last.tabView.activePane.view.webtermView.terminal.keyDown({type: 'keydown', keyCode: 13, stopPropagation: function() {}, preventDefault: function() {}});"


module.exports =

  acceptOrRejectInvitation: (browser, firstUser, secondUser, accept) ->

    firstUserName    = firstUser.username
    browser
      .waitForElementVisible     fullName, 20000
      .pause 2000
      .assert.containsText       fullName, firstUserName

    if accept
      browser
        .waitForElementVisible   acceptSharedMachine, 20000
        .click                   acceptSharedMachine
    else
      browser
        .waitForElementVisible   rejectSharedMachine, 20000
        .click                   rejectSharedMachine

    browser
      .waitForElementNotPresent  sidebarPopover, 20000
      .pause                     3000 # wait for sidebar redraw


  handleInvitation: (browser, host, participant, accept, callback) ->

    browser.pause 2000, =>
      browser.url url
      browser.maximizeWindow()
      teamsHelpers.loginToTeam browser, participant, no, '',  =>
        browser
          .waitForElementVisible closeModal, 20000
          .click closeModal
          .waitForElementVisible '.kdview', 20000

        @waitInvitation browser, (result) =>
          browser
            .click                     '#main-sidebar'
            .waitForElementVisible     sharedMachineSelector, 20000
            .moveToElement             sharedMachineSelector, 100, 10
            .click                     sharedMachineSelector
            .click                     sharedMachineSelector
            .waitForElementVisible     sidebarPopover, 20000
          browser.element 'css selector', acceptSharedMachine, (result) =>
            if result.status is 0
              @acceptOrRejectInvitation(browser, host, participant, accept)
          callback?()


  waitInvitation: (browser, callback) ->
    browser.element 'css selector', sharedMachineSelector, (result) =>
      if result.status is 0
        callback()
      else
        @waitInvitation browser, callback


  handleInvite: (browser, host, participant, isInvite, callback) ->

    participant.role = 'member'

    users = [
      participant
    ]

    queue = [
      (next) ->
        teamsHelpers.inviteAndJoinWithUsers browser, users, (result) ->
          browser.writeMemberInvitation 'Participant joined to team', ->
            next null, result
      (next) ->
        teamsHelpers.buildStack browser, (res) ->
          next null, res
    ]

    async.series queue
    if isInvite
      @shareTheMachineWithMembers browser, participant, (result) ->
        browser.pause 2000, callback
    else
      @checkInvitedUser  browser, participant, (result) ->
        callback?()


  checkInvitedUser: (browser, member, callback) ->

    memberNicknameToShareMachine = "@#{member.username}"
    browser
      .url virtualMachinesUrl
      .waitForElementVisible virtualMachineSelector, 20000
      .waitForElementVisible runningVMSelector, 20000
      .click runningVMSelector
      .scrollToElement addAConnectedMachineButtonSelector

    browser.element 'css selector', '.react-toggle--checked .react-toggle-track:last', (result) ->
      if result.status is -1
        browser.click closeModal, ->
          callback()
      else
        browser
          .waitForElementVisible membersList, 20000
          .waitForElementVisible removeSharedMachineMember, 20000
          .click closeModal, ->
            callback()


  shareTheMachineWithMembers: (browser, member, callback) ->

    memberNicknameToShareMachine = "@#{member.username}"
    browser
      .url virtualMachinesUrl
      .waitForElementVisible virtualMachineSelector, 20000
      .waitForElementVisible runningVMSelector, 20000
      .click runningVMSelector

    browser.element 'css selector', '.react-toggle--checked .react-toggle-track:last', (result) ->
      if result.status is -1
        browser
          .scrollToElement addAConnectedMachineButtonSelector
          .click vmSharingToggleSelector

    browser.element 'css selector', noFoundUserList, (result) ->
      if result.status is 0
        browser
          .waitForElementVisible inputSelector, 20000
          .setValue inputSelector, memberNicknameToShareMachine
          .click inputSelector
          .waitForElementVisible memberSelector, 20000
          .moveToElement memberSelector, 0, 0
          .click memberSelector
          .waitForElementVisible membersList, 20000
          .waitForElementVisible removeSharedMachineMember, 20000
          .click closeModal, ->
            callback()


  leaveMachine: (browser, participant, callback) ->
    browser.pause 3000, =>
      browser.url url
      browser.maximizeWindow()
      teamsHelpers.loginToTeam browser, participant, no, '',  =>
        browser
          .waitForElementVisible closeModal, 20000
          .click closeModal
        @openMachineSettings browser
        browser
          .waitForElementVisible     leaveSessionButton, 20000
          .click                     leaveSessionButton
          .waitForElementVisible     '.kdmodal-content', 20000
          .click                     proceedButton
          .waitForElementNotVisible  sharedMachineSelector, 30000, callback


  openMachineSettings: (browser) ->
    browser
      .waitForElementVisible     sharedMachineSelector, 20000
      .moveToElement             sharedMachineSelector, 100, 10
      .waitForElementVisible     sharedMachineButtonSettings, 20000
      .click                     sharedMachineButtonSettings
      .waitForElementVisible     sidebarPopover, 20000


  runCommandonTerminal: (browser, participant, callback) ->
    browser.url url
    browser.maximizeWindow()
    teamsHelpers.loginToTeam browser, participant, no, '',  ->
      browser
        .waitForElementVisible closeModal, 20000
        .click closeModal
        .click sharedMachineSelector
        .click sharedMachineSelector

      browser.element 'css selector', activeTerminal, (result) ->
        if result.status is -1
          terminalHelpers.openNewTerminalMenu(browser)
          terminalHelpers.openTerminal(browser)

        helpers.runCommandOnTerminal(browser, 'Text pasted into the terminal')
          #clearing the terminal for second test run
        browser
          .execute  "#{insertCommand}('clear')"
          .execute  executeCommand
          .pause    5000, callback


  createFile: (browser, host, participant, fileName, callback) ->
    browser.url url
    browser.maximizeWindow()
    teamsHelpers.loginToTeam browser, participant, no, '',  ->
      browser
        .waitForElementVisible closeModal, 20000
        .click closeModal
        .click sharedMachineSelector
        .click sharedMachineSelector
      helpers.createFile(browser, host, null, null, fileName)
      browser.pause  3000, callback


  removeUser: (browser, host, member, callback) ->
    browser
      .url virtualMachinesUrl
      .waitForElementVisible virtualMachineSelector, 20000
      .waitForElementVisible runningVMSelector, 20000
      .click runningVMSelector
      .scrollToElement addAConnectedMachineButtonSelector
      .waitForElementVisible membersList, 20000
      .moveToElement membersList, 0, 0
      .click membersList
      .waitForElementVisible removeSharedMachineMember, 20000
      .click removeSharedMachineMember, ->
        browser.pause 3000, callback
