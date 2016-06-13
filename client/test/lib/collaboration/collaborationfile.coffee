utils                = require '../utils/utils.js'
helpers              = require '../helpers/helpers.js'
collaborationHelpers = require '../helpers/collaborationhelpers.js'
ideHelpers           = require '../helpers/idehelpers.js'
terminalHelpers      = require '../helpers/terminalhelpers.js'
assert               = require 'assert'
teamsHelpers         = require '../helpers/teamshelpers.js'
async                = require 'async'


module.exports =


  before: (browser) -> utils.beforeCollaborationSuite browser

  afterEach: (browser, done) -> utils.afterEachCollaborationTest browser, done

  checkIfInvitedUserCanEditFilesOtherUserVm: (browser) ->

    host               = utils.getUser no, 0
    hostBrowser        = process.env.__NIGHTWATCH_ENV_KEY is 'host_1'
    participant        = utils.getUser no, 1
    hostFakeText       = host.fakeText.split(' ')
    fileName           = hostFakeText[0]
    fileSlug           = fileName.replace '.', ''
    tabSelector        = ".kdtabhandle.#{fileSlug}"
    editorSelector     = ".kdtabpaneview.#{fileSlug} .ace_content"
    hostContent        = hostFakeText[1]
    participantContent = participant.fakeText.split(' ')[0]

    hostCallback = ->

      helpers.createFile(browser, host, null, null, fileName)
      ideHelpers.openFile(browser, host, fileName)
      ideHelpers.setTextToEditor(browser, hostContent)
      collaborationHelpers.answerPermissionRequest(browser, yes)
      browser.waitForTextToContain(editorSelector, participantContent)
      collaborationHelpers.waitParticipantLeaveAndEndSession(browser)
      browser.end()

    participantCallback = ->

      browser
        .waitForElementPresent tabSelector, 50000 # Assertion
        .pause 3000
        .waitForElementVisible editorSelector, 20000
        .waitForTextToContain  editorSelector, hostContent
        .pause 3000

      collaborationHelpers.requestPermission(browser, yes)
      ideHelpers.setTextToEditor(browser, participantContent)
      collaborationHelpers.leaveSessionFromStatusBar(browser)
      browser.end()

    collaborationHelpers.initiateCollaborationSession(browser, hostCallback, participantCallback)


  checkIfInvitedUserCanSeeExistingOpenIDETabs: (browser) ->
    host        = utils.getUser no, 0
    fileSelector = "span[title='/home/#{host.username}/.config/python.py']"
    htmlFileSelector = "span[title='/home/#{host.username}/.config/index.html']"


    hostCallback = ->
      browser.pause 3000
      helpers.deleteFile(browser, fileSelector)
      helpers.deleteFile(browser, htmlFileSelector)

      collaborationHelpers.waitParticipantLeaveAndEndSession(browser)

      browser.end()

    participantCallback = ->

      browser
        .waitForElementVisible  '.kdtabhandle.indexhtml', 20000
        .waitForElementVisible  '.kdtabhandle.pythonpy', 20000
        .waitForElementVisible  '.kdtabhandle.terminal', 20000

      collaborationHelpers.leaveSessionFromStatusBar(browser)
      browser.end()

    collaborationHelpers.initiateCollaborationSession(browser, hostCallback, participantCallback, yes)
