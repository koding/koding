assert   = require 'assert'
helpers  = require '../helpers/helpers.js'
async    = require 'async'
helpers  = require '../helpers/helpers.js'
environmentHelpers = require '../helpers/environmenthelpers.js'
teamsHelpers       = require '../helpers/teamshelpers.js'
utils      = require '../utils/utils.js'


virtualMachinesUrl      = "#{helpers.getUrl(yes)}/Home/Stacks/virtual-machines"
machineSharingDetails   = '.MachineSharingDetails'
inputSelector           = "#{machineSharingDetails} input.kdinput.text"
memberSelector          = "#{machineSharingDetails} .AutocompleteListItem"
membersList             = "#{machineSharingDetails} .UserList"
sharedUserlist          = "#{machineSharingDetails} .UserList"
noFoundUserList         = "#{machineSharingDetails} .NoItem"
addAConnectedMachineButtonSelector = '.kdbutton.GenericButton.HomeAppViewVMSection--addOwnMachineButton'
machineDetailSelector   = '.MachinesListItem-machineDetails'
vmSharingSelector       = "#{machineDetailSelector} .MachineDetails div.GenericToggler:nth-of-type(4)"
vmSharingToggleSelector = "#{vmSharingSelector} .react-toggle-thumb"
virtualMachineSelector  = '.HomeAppView--section.virtual-machines'
runningVMSelector       = "#{virtualMachineSelector} .MachinesListItem-machineLabel.Running"

sidebarSharedMachinesSection = '.SidebarSection.SidebarSharedMachinesSection'
sidebarPopover           = '.Popover-Wrapper'
acceptSharedMachine      = "#{sidebarPopover} .kdbutton.solid.green.medium"
rejectSharedMachine      = "#{sidebarPopover} .kdbutton.solid.red.medium"
closeModal               = '.HomeWelcomeModal.kdmodal .kdmodal-inner .close-icon.closeModal'
fullName         = '.SidebarWidget-FullName'

module.exports =

  acceptOrRejectInvitation: (browser, firstUser, secondUser, accept) ->

    firstUserName    = firstUser.username
    browser
      .waitForElementVisible     sidebarPopover, 50000
      .waitForElementVisible     fullName, 20000
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


  handleInvitation: (browser, host, participant, accept, endSessionAfterAcceptingInvite = yes) ->

    sharedMachineSelector = '.activity-sidebar .shared-machines .sidebar-machine-box .vm.running'

    url = helpers.getUrl(yes)
    
    browser.pause 5000, =>
      browser.url url
      browser.maximizeWindow()
      teamsHelpers.loginToTeam browser, participant, no, '',  =>
        browser
          .waitForElementVisible closeModal, 20000
          .click closeModal
          .waitForElementVisible '.kdview', 20000
        
        browser.element 'css selector', sidebarSharedMachinesSection, (result) ->
          if result.status is 0
            browser
              .waitForElementPresent  sidebarSharedMachinesSection, 20000
            @acceptOrRejectInvitation(browser, host, participant, accept)

        if endSessionAfterAcceptingInvite
          browser.end()


  handleInvite: (browser, host, participant, callback) ->

    modalSelector         = '.computeplan-modal.free-plan .kdmodal-inner'
    userSelector          = '.listview-wrapper .kdlistitemview-user'
    sharedMachineSelector = '.activity-sidebar .shared-machines .sidebar-machine-box .vm.running'
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
    @shareTheMachineWithMembers browser, participant, (result) ->
      browser.pause 4000, callback 

  
  shareTheMachineWithMembers: (browser, member, callback) ->
    removeSharedMachineMember = "#{membersList} .remove"
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
          .click memberSelector
          .waitForElementVisible membersList, 20000
          .waitForElementVisible removeSharedMachineMember, 20000, callback


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
