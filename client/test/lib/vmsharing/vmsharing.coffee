utils           = require '../utils/utils.js'
vmHelpers       = require '../helpers/vmhelpers.js'
terminalHelpers = require '../helpers/terminalhelpers.js'
helpers         = require '../helpers/helpers.js'
teamsHelpers    = require '../helpers/teamshelpers.js'
ideHelpers      = require '../helpers/idehelpers.js'
assert          = require 'assert'
url             = helpers.getUrl(yes)
host            = utils.getUser no, 0
hostBrowser     = process.env.__NIGHTWATCH_ENV_KEY is 'host_1'
participant     = utils.getUser no, 1
sharedMachineSelector = '.SidebarMachinesListItem.Running'
closeModal = '.HomeWelcomeModal.kdmodal .kdmodal-inner .close-icon.closeModal'
proceedButton = '[testpath=proceed]'
addAConnectedMachineButtonSelector = '.kdbutton.GenericButton.HomeAppViewVMSection--addOwnMachineButton'
vmSharingListSelector = '.vm-sharing.active'
terminalSelector = '.kdview.ws-tabview .application-tabview .terminal'
machineDetailSelector = '.MachinesListItem-machineDetails'
vmSharingSelector = "#{machineDetailSelector} .MachineDetails div.GenericToggler:nth-of-type(4)"
vmSharingToggleSelector = "#{vmSharingSelector} .react-toggle-thumb"
noFoundUserList = '.MachineSharingDetails .NoItem'


module.exports =

  before: (browser) -> utils.beforeCollaborationSuite browser

  shareVMAndRejectInvitaion: (browser) ->

    callback = ->
      browser.end()

    participantCallback = ->
      browser.end()

    if hostBrowser
      vmHelpers.handleInvite(browser, host, participant, yes, callback)
    else
      vmHelpers.handleInvitation(browser, host, participant, no, participantCallback)


  shareVMAndAcceptInvitaion: (browser) ->

    callback = ->
      browser.end()

    participantCallback = ->
      browser.end()

    if hostBrowser
      vmHelpers.handleInvite(browser, host, participant, yes, callback)
    else
      vmHelpers.handleInvitation(browser, host, participant, yes, participantCallback)


  shareVMAcceptInvitaionAndRunOnTerminal: (browser) ->

    browser.pause 2500, -> # wait for user.json creation
      callback = ->
        browser.pause 3000 # wait for participant to clear terminal for second run
        browser.end()

      participantCallback = ->
        browser.end()

      if hostBrowser
        vmHelpers.handleInvite(browser, host, participant, no, callback)
      else
        vmHelpers.runCommandonTerminal(browser, participant, participantCallback)


  createNewFile: (browser) ->

    hostFakeText = host.fakeText.split(' ')
    fileName     = hostFakeText[0]
    fileContent  = hostFakeText[1]
    hostFileName = hostFakeText[2]
    newFileName  = hostFakeText[3]
    hostFileSelector =  "span[title='/home/#{host.username}/.config/#{hostFileName}']"
    fileSelector =  "span[title='/home/#{host.username}/.config/#{fileName}']"
    fileSlug = hostFileName.replace '.', ''

    browser.pause 2500, -> # wait for user.json creation
      callback = ->

        helpers.createFile(browser, host, null, null, hostFileName)
        ideHelpers.openFileFromConfigFolder(browser, host, hostFileName, fileContent)
        browser.waitForElementVisible  fileSelector, 40000
        browser.refresh()
        editorSelector = ".kdtabpaneview.#{fileSlug} .ace_content"
        browser.waitForElementVisible  editorSelector, 30000
        browser.assert.containsText editorSelector, fileContent
        ideHelpers.closeFile(browser, hostFileName, host)
        ideHelpers.openFile(browser, host, fileName)
        ideHelpers.closeFile(browser, fileName, host)
        browser.waitForElementVisible  "span[title='/home/#{host.username}/newFile.txt']", 50000
        browser.end()

      participantCallback = ->

        browser.waitForElementVisible  hostFileSelector, 70000
        ideHelpers.openFile(browser, host, hostFileName)
        browser.pause 2000
        ideHelpers.setTextToEditor(browser, fileContent)
        ideHelpers.saveFile(browser)
        ideHelpers.closeFile(browser, hostFileName, host)
        helpers.createFile(browser, host, null, null, newFileName)
        ideHelpers.openFile(browser, host, newFileName)
        ideHelpers.saveAsFile(browser)
        browser.end()

      if hostBrowser
        vmHelpers.handleInvite(browser, host, participant, no, callback)
      else
        vmHelpers.createFile(browser, host, participant, fileName, participantCallback)

  leaveVMSharing: (browser) ->

    browser.pause 2500, -> # wait for user.json creation
      callback = ->
        browser.end()

      participantCallback = ->
        browser.end()

      if hostBrowser
        vmHelpers.handleInvite(browser, host, participant, no, callback)
      else
        vmHelpers.leaveMachine(browser, participant, participantCallback)


  removeUserFromVmSharing:(browser) ->

    browser.pause 2500, -> # wait for user.json creation
      callback = ->
        vmHelpers.removeUser browser, host, participant, ->
          browser.refresh()
          browser
            .waitForElementVisible machineDetailSelector, 20000
            .scrollToElement addAConnectedMachineButtonSelector
          browser.element 'css selector', '.react-toggle--checked .react-toggle-track:last', (result) ->
            if result.status is -1
              browser
                .click vmSharingToggleSelector
                .waitForElementVisible noFoundUserList, 20000
                .end()

      participantCallback = ->
        browser
          .waitForElementVisible '.kdmodal-inner', 40000
          .assert.containsText '.kdmodal-content', 'Machine access revoked'
          .waitForElementVisible proceedButton, 20000
          .click proceedButton
          .waitForElementNotPresent sharedMachineSelector, 60000
          .end()

      if hostBrowser
        vmHelpers.handleInvite(browser, host, participant, yes, callback)
      else
        vmHelpers.handleInvitation(browser, host, participant, yes, participantCallback)
