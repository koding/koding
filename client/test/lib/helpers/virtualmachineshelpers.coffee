teamsHelpers            = require '../helpers/teamshelpers.js'
helpers                 = require '../helpers/helpers.js'
utils                   = require '../utils/utils.js'
virtualMachinesUrl      = "#{helpers.getUrl(yes)}/Home/stacks/virtual-machines"
virtualMachineSelector  = '.HomeAppView--section.virtual-machines'
runningVMSelector       = '.MachinesListItem-detailToggle'
machineDetailSelector   = '.MachinesListItem-machineDetails'
machineDetailSpecsList  = "#{machineDetailSelector} .MachineDetails-SpecsList"
vmPowerSelector         = "#{machineDetailSelector} .MachineDetails div.GenericToggler:nth-of-type(2)"
alwaysOnSelector        = "#{machineDetailSelector} .MachineDetails div.GenericToggler:nth-of-type(3)"
vmSharingSelector       = "#{machineDetailSelector} .MachineDetails div.GenericToggler:nth-of-type(4)"
vmPowerToggleSelector   = "#{vmPowerSelector} .react-toggle-thumb"
alwaysOnToggleSelector  = "#{alwaysOnSelector} .react-toggle-thumb"
vmSharingToggleSelector = "#{vmSharingSelector} .react-toggle-thumb"
machineSharingDetails   = '.MachineSharingDetails'
inputSelector           = "#{machineSharingDetails} input.kdinput.text"
memberSelector          = "#{machineSharingDetails} .AutocompleteListItem"
membersList             = "#{machineSharingDetails} .UserList"
sharedUserlist          = "#{machineSharingDetails} .UserList"
noFoundUserList         = "#{machineSharingDetails} .NoItem"

addAConnectedMachineButtonSelector = '.kdbutton.GenericButton.HomeAppViewVMSection--addOwnMachineButton'
addYourOwnMachineSelector          = '.kdmodal.add-managed-vm.kddraggable'

selectButtonSelector               = "#{addYourOwnMachineSelector} .code .select-all"
closeAddYourOwnMachineModal        = "#{addYourOwnMachineSelector} .close-icon.closeModal"
pressCMDCNotificationSelector      = 'input.kdinput.text:focus, textarea.kdinput.text:focus'

sidebarSharedMachinesSection       = '.SidebarSection.SidebarSharedMachinesSection'
sidebarPopover                     = '.Popover-Wrapper'
acceptSharedMachine                = '.SidebarWidget .Popover-Wrapper button.accept'
rejectSharedMachine                = '.SidebarWidget .Popover-Wrapper button.reject'

sharedMachineSection               = '.HomeAppView--section.shared-machines'
sharedMachinesList                 = "#{sharedMachineSection} .ListView"

module.exports =

  seeOwnMachinesList: (browser, callback) ->
    browser
      .pause 5000
      .url virtualMachinesUrl
      .waitForElementVisible virtualMachineSelector, 20000
      .waitForElementVisible runningVMSelector, 20000
      .click runningVMSelector
      .waitForElementVisible machineDetailSelector, 20000, callback


  # check for specsList
  seeSpecificationOfMachine: (browser, callback) ->
    browser
      .waitForElementVisible machineDetailSpecsList, 20000, callback

  # vm off by using VM Power toggle
  toggleOnOffMachine: (browser, callback) ->
    browser
      .click vmPowerToggleSelector, ->
        teamsHelpers.waitUntilVmStopping browser, ->
          browser
            .click vmPowerToggleSelector, ->
              teamsHelpers.waitUntilVmRunning browser, ->
                browser.pause 1000, callback


  # check for alwaysOnToggle
  toggleAlwaysOnMachine: (browser, callback) ->
    browser
      .click alwaysOnToggleSelector
      .pause 1000
      .click alwaysOnToggleSelector
      .pause 1000, callback


  # check for vmSharingToggle and share the machine
  shareTheMachineWithMembers: (browser, member, callback) ->
    removeSharedMachineMember = "#{membersList} .remove"
    memberNicknameToShareMachine = "@#{member.username}"
    browser
      .scrollToElement addAConnectedMachineButtonSelector
      .click vmSharingToggleSelector
      .waitForElementVisible inputSelector, 20000
      .setValue inputSelector, memberNicknameToShareMachine
      .click inputSelector
      .waitForElementVisible memberSelector, 20000
      .click memberSelector
      .waitForElementVisible membersList, 20000
      .waitForElementVisible removeSharedMachineMember, 20000, callback


  # check shared machine for member
  acceptSharedMachine: (browser, host, member, callback) ->

    @shareTheMachineWithMembers browser, member, ->
      teamsHelpers.logoutTeamfromUrl browser, ->
        teamsHelpers.loginToTeam browser, member, no, null, ->
          browser
            .waitForElementVisible sidebarSharedMachinesSection, 20000
            .click sidebarSharedMachinesSection
            .waitForElementVisible sidebarPopover, 20000
            .click acceptSharedMachine
            .pause 2000
            .url virtualMachinesUrl
            .waitForElementVisible virtualMachineSelector, 20000
            .waitForElementVisible sharedMachineSection, 20000
            .waitForElementVisible sharedMachinesList, 20000
            .pause 2000, ->
              teamsHelpers.logoutTeamfromUrl browser, ->
                teamsHelpers.loginToTeam browser, host, no, null, ->
                  browser
                    .pause 2000
                    .url virtualMachinesUrl
                    .waitForElementVisible virtualMachineSelector, 20000
                    .waitForElementVisible runningVMSelector, 20000
                    .click runningVMSelector
                    .waitForElementVisible machineDetailSelector, 20000, callback


  rejectAndAcceptSharedMachine: (browser, host, member, callback) ->

    @shareTheMachineWithMembers browser, member, =>
      teamsHelpers.logoutTeamfromUrl browser, =>
        teamsHelpers.loginToTeam browser, member, no, null, =>
          browser
            .waitForElementVisible sidebarSharedMachinesSection, 20000
            .click sidebarSharedMachinesSection
            .waitForElementVisible sidebarPopover, 20000
            .click rejectSharedMachine
            .pause 2000
            .url virtualMachinesUrl
            .waitForElementVisible virtualMachineSelector, 20000
            .waitForElementVisible sharedMachineSection, 20000
            .waitForElementVisible sharedMachinesList, 20000
            .pause 2000, =>
              teamsHelpers.logoutTeamfromUrl browser, =>
                teamsHelpers.loginToTeam browser, host, no, null, =>
                  browser
                    .pause 2000
                    .url virtualMachinesUrl
                    .waitForElementVisible virtualMachineSelector, 20000
                    .waitForElementVisible runningVMSelector, 20000
                    .click runningVMSelector
                    .waitForElementVisible machineDetailSelector, 20000
                    .click vmSharingToggleSelector
                    .waitForElementVisible noFoundUserList, 20000
                    .click vmSharingToggleSelector
                    .pause 1000, =>
                      @acceptSharedMachine browser, host, member, ->
                        browser.pause 1000, callback


  removeAccessFromSharedMachine: (browser, callback) ->
    member = utils.getUser no, 1
    removeUser = "#{sharedUserlist} .remove"
    browser
      .waitForElementVisible membersList, 20000
      .moveToElement sharedUserlist, 0, 0
      .waitForElementVisible removeUser, 20000
      .click removeUser
      .pause 1000, callback


  #check add a Connected Machine
  seeConnectedMachinesList: (browser, callback) ->
    browser
      .url virtualMachinesUrl
      .scrollToElement addAConnectedMachineButtonSelector
      .waitForElementVisible addAConnectedMachineButtonSelector, 20000
      .click addAConnectedMachineButtonSelector
      .waitForElementVisible addYourOwnMachineSelector, 20000
      .waitForElementVisible selectButtonSelector, 20000
      .click selectButtonSelector
      .waitForElementVisible pressCMDCNotificationSelector, 20000
      .waitForElementVisible closeAddYourOwnMachineModal, 20000
      .click closeAddYourOwnMachineModal
      .pause 1000, callback


  seeSharedMachinesList: (browser, callback) ->
    browser
      .url virtualMachinesUrl
      .scrollToElement sharedMachineSection
      .waitForElementVisible sharedMachineSection, 20000
      .waitForElementVisible sharedMachinesList, 20000, callback
