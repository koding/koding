teamsHelpers = require '../helpers/teamshelpers.js'
helpers = require '../helpers/helpers.js'
utils = require '../utils/utils.js'
virtualMachinesUrl = "#{helpers.getUrl(yes)}/Home/Stacks/virtual-machines"
async = require 'async'


module.exports =

  before: (browser, done) ->

    ###
    * we are creating users list here to send invitation and join to team
    * so we will be able to run our test for different kind of member role
    ###
    targetUser1 = utils.getUser no, 1
    targetUser1.role = 'member'

    users = [
      targetUser1
    ]

    queue = [
      (next) ->
        teamsHelpers.inviteAndJoinWithUsers browser, users, (result) ->
          next null, result
      (next) ->
        teamsHelpers.buildStack browser, (res) ->
          next null, res
    ]

    async.series queue, (err, result) ->
      done()  unless err


  virtualmachines: (browser) ->

    member = utils.getUser no, 1
    host = utils.getUser()

    virtualMachineSelector = '.HomeAppView--section.virtual-machines'
    runningVMSelector = "#{virtualMachineSelector} .MachinesListItem-machineLabel.Running"
    machineDetailSelector = '.MachinesListItem-machineDetails'
    machineDetailSpecsList = "#{machineDetailSelector} .MachineDetails-SpecsList"
    vmPowerSelector = "#{machineDetailSelector} .MachineDetails div.GenericToggler:nth-of-type(2)"
    alwaysOnSelector = "#{machineDetailSelector} .MachineDetails div.GenericToggler:nth-of-type(3)"
    vmSharingSelector = "#{machineDetailSelector} .MachineDetails div.GenericToggler:nth-of-type(4)"
    vmPowerToggleSelector = "#{vmPowerSelector} .react-toggle-thumb"
    alwaysOnToggleSelector = "#{alwaysOnSelector} .react-toggle-thumb"
    vmSharingToggleSelector = "#{vmSharingSelector} .react-toggle-thumb"
    machineSharingDetails = '.MachineSharingDetails'
    inputSelector = "#{machineSharingDetails} input.kdinput.text"
    memberSelector = "#{machineSharingDetails} .AutocompleteListItem"
    membersList = "#{machineSharingDetails} .ListView"
    removeSharedMachineMember = "#{membersList} .remove"
    memberNicknameToShareMachine = "@#{member.username}"

    addAConnectedMachineButtonSelector = '.kdbutton.GenericButton.HomeAppViewVMSection--addOwnMachineButton'
    addYourOwnMachineSelector = '.kdmodal.add-managed-vm'

    selectButtonSelector = "#{addYourOwnMachineSelector} .code .select-all"
    closeAddYourOwnMachineModal = "#{addYourOwnMachineSelector} .close-icon.closeModal"
    pressCMDCNotificationSelector = '.kdview.kdtooltip.just-text.placement-top.direction-center'

    sidebarSharedMachinesSection = '.SidebarSection.SidebarSharedMachinesSection'
    sidebarPopover = '.Popover-Wrapper'
    acceptSharedMachine = "#{sidebarPopover} .kdbutton.solid.green.medium"

    sharedMachineSection = '.HomeAppView--section.shared-machines'
    sharedMachinesList = "#{sharedMachineSection} .ListView"


    browser
      .pause 5000
      .url virtualMachinesUrl
      .waitForElementVisible virtualMachineSelector, 20000
      .waitForElementVisible runningVMSelector, 20000
      .click runningVMSelector
      .waitForElementVisible machineDetailSelector, 20000

    # check for specsList
    browser
      .waitForElementVisible machineDetailSpecsList, 20000

    # check for alwaysOnToggle
    browser
      .click alwaysOnToggleSelector
      .pause 1000
      .click alwaysOnToggleSelector
      .pause 1000

    # check for vmSharingToggle
    browser
      .click vmSharingToggleSelector
      .waitForElementVisible inputSelector, 20000
      .setValue inputSelector, memberNicknameToShareMachine
      .click inputSelector
      .waitForElementVisible memberSelector, 20000
      .click memberSelector
      .waitForElementVisible membersList, 20000
      .waitForElementVisible removeSharedMachineMember, 20000, ->

        # check shared machine for member
        teamsHelpers.logoutTeam browser, ->
          teamsHelpers.loginToTeam browser, member, no, ->
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
                teamsHelpers.logoutTeam browser, ->
                  teamsHelpers.loginToTeam browser, host, no, ->
                    browser
                      .pause 2000
                      .url virtualMachinesUrl
                      .waitForElementVisible virtualMachineSelector, 20000
                      .waitForElementVisible runningVMSelector, 20000
                      .click runningVMSelector

    #check add a Connected Machine
    browser
      .waitForElementVisible addAConnectedMachineButtonSelector, 20000
      .click addAConnectedMachineButtonSelector
      .waitForElementVisible addYourOwnMachineSelector, 20000
      .waitForElementVisible selectButtonSelector, 20000
      .click selectButtonSelector
      .waitForElementVisible pressCMDCNotificationSelector, 20000
      .waitForElementVisible closeAddYourOwnMachineModal, 20000
      .click closeAddYourOwnMachineModal
      .pause 1000

    # vm off by using VM Power toggle
    browser
      .click vmPowerToggleSelector, ->
        teamsHelpers.waitUntilVmStopping browser, ->
          browser
            .click vmPowerToggleSelector, ->
              teamsHelpers.waitUntilVmRunning browser, ->
                browser.end()
