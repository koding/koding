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


module.exports =

  before: (browser) -> utils.beforeCollaborationSuite browser

  shareVMAndRejectInvitaion: (browser) ->

    host                  = utils.getUser no, 0
    hostBrowser           = process.env.__NIGHTWATCH_ENV_KEY is 'host_1'
    participant           = utils.getUser no, 1

    callback = ->
      browser.end()

    if hostBrowser
      vmHelpers.handleInvite(browser, host, participant, yes, callback)
    else
      vmHelpers.handleInvitation(browser, host, participant, no, callback)


  shareVMAndAcceptInvitaion: (browser) ->

    host                  = utils.getUser no, 0
    hostBrowser           = process.env.__NIGHTWATCH_ENV_KEY is 'host_1'
    participant           = utils.getUser no, 1

    callback = ->
      browser.end()

    if hostBrowser
      vmHelpers.handleInvite(browser, host, participant, yes, callback)
    else
      vmHelpers.handleInvitation(browser, host, participant, yes, callback)


  shareVMAcceptInvitaionAndRunOnTerminal: (browser) ->

    vmSharingListSelector = '.vm-sharing.active'
    terminalSelector      = '.kdview.ws-tabview .application-tabview .terminal'

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
    hostFileSelector =  "span[title='/home/#{host.username}/.config/#{hostFileName}']" 
    fileSelector =  "span[title='/home/#{host.username}/.config/#{fileName}']"
    fileSlug = hostFileName.replace '.', ''
    
    browser.pause 2500, -> # wait for user.json creation
      callback = ->
        helpers.createFile(browser, host, null, null, hostFileName)
        browser.end()

      participantCallback = ->
        
        browser.waitForElementVisible  hostFileSelector, 20000
        ideHelpers.openFile(browser, host, hostFileName)
        
        browser.end()

      if hostBrowser
        vmHelpers.handleInvite(browser, host, participant, no, callback)
      else
        vmHelpers.CreateFile(browser, host, participant,fileName, participantCallback)
         

  leaveVMSharing: (browser) ->

    host                  = utils.getUser no, 0
    hostBrowser           = process.env.__NIGHTWATCH_ENV_KEY is 'host_1'
    participant           = utils.getUser no, 1

    browser.pause 2500, -> # wait for user.json creation
      if hostBrowser
        callback = ->
          browser.end()

        vmHelpers.handleInvite(browser, host, participant, no, callback)
      else
        vmHelpers.leaveMachine(browser, participant, callback)

