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

    users =
      targetUser1

    queue = [
      (next) ->
        teamsHelpers.inviteAndJoinWithUsers browser, [ users ], (result) ->
          next null, result
      (next) ->
        teamsHelpers.buildStack browser, (res) ->
          next null, res
    ]

    async.series queue, (err, result) ->
      done()  unless err


  virtualmachines: (browser) ->

    member = utils.getUser no, 1

    virtualMachineSelector = '.HomeAppView--section.virtual-machines'
    runningVMSelector = "#{virtualMachineSelector} .MachinesListItem-machineLabel.Running"
    machineDetailSelector = '.MachinesListItem-machineDetails'
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


    browser
      .pause 5000
      .url virtualMachinesUrl
      .waitForElementVisible virtualMachineSelector, 20000
      .waitForElementVisible runningVMSelector, 20000
      .click runningVMSelector
      .waitForElementVisible machineDetailSelector, 20000

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
      .waitForElementVisible removeSharedMachineMember, 20000
      .click removeSharedMachineMember
      .pause 2000
      .click vmSharingToggleSelector

