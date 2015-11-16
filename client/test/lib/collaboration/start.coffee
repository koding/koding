utils                = require '../utils/utils.js'
helpers              = require '../helpers/helpers.js'
ideHelpers           = require '../helpers/idehelpers.js'
collaborationHelpers = require '../helpers/collaborationhelpers.js'
terminalHelpers      = require '../helpers/terminalhelpers.js'
assert               = require 'assert'


chatBox  = '.collaboration.message-pane'


startSession = (browser, firstUser, secondUser) ->

  secondUserName         = secondUser.username
  secondUserAvatar       = ".avatars .avatarview[href='/#{secondUserName}']"
  secondUserOnlineAvatar = secondUserAvatar + '.online'
  chatTextSelector       = '.status-bar a.active'

  helpers.beginTest browser, firstUser
  helpers.waitForVMRunning browser

  collaborationHelpers.isSessionActive browser, (isActive) ->

    if isActive then browser.end()
    else
      collaborationHelpers.startSession browser
      collaborationHelpers.inviteUser   browser, secondUserName

      browser
        .waitForElementVisible  secondUserAvatar, 60000
        .waitForElementVisible  secondUserOnlineAvatar, 50000 # Assertion
        .waitForElementVisible  chatTextSelector, 50000
        .assert.containsText    chatTextSelector, 'CHAT' # Assertion


joinSession = (browser, firstUser, secondUser) ->

  firstUserName    = firstUser.username
  secondUserName   = secondUser.username
  sharedMachineBox = '[testpath=main-sidebar] .shared-machines:not(.hidden)'
  shareModal       = '.share-modal'
  fullName         = shareModal + ' .user-details .fullname'
  acceptButton     = shareModal + ' .kdbutton.green'
  rejectButton     = shareModal + ' .kdbutton.red'
  loadingButton    = acceptButton + '.loading'
  selectedMachine  = '.sidebar-machine-box.selected'
  filetree         = '.ide-files-tab'
  message          = '.kdlistitemview-activity.privatemessage'
  chatUsers        = "#{chatBox} .chat-heads"
  userAvatar       = ".avatars .avatarview.online[href='/#{firstUserName}']"
  chatTextSelector = '.status-bar a.active'

  helpers.beginTest browser, secondUser

  browser.element 'css selector', sharedMachineBox, (result) =>

    if result.status is 0
      browser.end()
    else
      browser
        .waitForElementVisible     shareModal, 200000 # wait for vm turn on for host
        .waitForElementVisible     fullName, 50000
        .assert.containsText       shareModal, firstUserName
        .waitForElementVisible     acceptButton, 50000
        .waitForElementVisible     rejectButton, 50000
        .click                     acceptButton
        .waitForElementVisible     loadingButton, 50000
        .waitForElementNotPresent  shareModal, 50000
        .pause                     3000 # wait for sidebar redraw
        .waitForElementVisible     selectedMachine, 50000
        .waitForElementVisible     chatBox, 50000
        .waitForElementVisible     chatUsers, 50000
        .waitForElementVisible     message, 50000
        .assert.containsText       chatBox, firstUserName
        .assert.containsText       chatBox, secondUserName
        .assert.containsText       filetree, firstUserName
        .waitForElementVisible     userAvatar, 50000 # Assertion
        .waitForElementVisible     chatTextSelector, 50000
        .assert.containsText       chatTextSelector, 'CHAT' # Assertion


start = (browser) ->

  host        = utils.getUser no, 0
  participant = utils.getUser no, 1

  console.log " ✔ Starting collaboration test..."
  console.log " ✔ Host: #{host.username}"
  console.log " ✔ Participant: #{participant.username}"

  hostBrowser = process.env.__NIGHTWATCH_ENV_KEY is 'host_1'

  if hostBrowser
    startSession browser, host, participant
  else
    joinSession browser, host, participant


leave = (browser) ->

  participant  = utils.getUser no, 1
  hostBrowser  = process.env.__NIGHTWATCH_ENV_KEY is 'host_1'

  unless hostBrowser
    collaborationHelpers.leaveSessionFromStatusBar(browser)
    # assert that no shared vm on sidebar


waitAndEndSession = (browser) ->

  host        = utils.getUser no, 0
  hostBrowser = process.env.__NIGHTWATCH_ENV_KEY is 'host_1'
  participant  = utils.getUser no, 1

  participantAvatar = ".avatars .avatarview.online[href='/#{participant.username}']"

  if hostBrowser
    browser.waitForElementNotPresent participantAvatar, 60000
    collaborationHelpers.endSessionFromStatusBar(browser)


module.exports =


  start: (browser) ->

    start(browser)
    leave(browser)
    waitAndEndSession(browser)

    browser.end()


  runCommandOnInviteUserTerminal: (browser) ->

    host         = utils.getUser no, 0
    hostBrowser  = process.env.__NIGHTWATCH_ENV_KEY is 'host_1'
    participant  = utils.getUser no, 1
    terminalText = host.teamSlug

    start(browser)
    collaborationHelpers.closeChatPage(browser)

    if hostBrowser
      helpers.runCommandOnTerminal(browser, terminalText)
    else
      # wait for terminal command appears on participant
      # we couldn't find a better way to avoid this pause
      # because there is no way to be sure when some text
      # is inserted to terminal or we couldn't find a way. - acetgiller
      browser.pause 5000
      browser.assert.containsText '.kdtabpaneview.terminal', terminalText

    leave(browser)
    waitAndEndSession(browser)

    browser.end()


  openFile: (browser) ->

    host                   = utils.getUser no, 0
    hostBrowser            = process.env.__NIGHTWATCH_ENV_KEY is 'host_1'
    participant            = utils.getUser no, 1
    paneSelector           = '.pane-wrapper .application-tab-handle-holder'
    lineWidgetSelector     = ".kdtabpaneview.active .ace-line-widget-"
    participantFileName    = 'python.py'
    participantFileContent = 'Hello World from Python by Koding'

    start(browser)
    collaborationHelpers.closeChatPage(browser)

    if hostBrowser
      ideHelpers.openFileFromWebFolder browser, host

      # wait for participant file opening
      browser
        .waitForElementVisible "#{paneSelector} .pythonpy",  60000
        # .waitForElementVisible "#{lineWidgetSelector}#{participant.username}", 60000
    else
      # wait for host file opening
      browser.waitForElementVisible "#{paneSelector} .indexhtml", 60000

      # open file in host's vm
      ideHelpers.openFileFromWebFolder browser, host, participantFileName, participantFileContent
      # browser.waitForElementVisible "#{lineWidgetSelector}#{host.username}", 60000

    leave(browser)

    # assert no line widget after participant left
    # browser.waitForElementNotPresent "#{lineWidgetSelector}#{participant.username}", 60000

    waitAndEndSession(browser)
    browser.end()


  openTerminalWithInvitedUser: (browser) ->

    host         = utils.getUser no, 0
    hostBrowser  = process.env.__NIGHTWATCH_ENV_KEY is 'host_1'
    participant  = utils.getUser no, 1
    paneSelector = '.pane-wrapper .kdsplitview-panel.panel-1 .application-tab-handle-holder'
    terminalTabs = "#{paneSelector} .terminal"

    start(browser)
    collaborationHelpers.closeChatPage(browser)

    browser.elements 'css selector', terminalTabs, (result) =>
      length = result.value.length

      if hostBrowser then browser.pause 10000
      else
        terminalHelpers.openNewTerminalMenu(browser)
        terminalHelpers.openTerminal(browser)

      browser.elements 'css selector', terminalTabs, (result) =>
        newLength = result.value.length

        assert.equal newLength, length + 1

    leave(browser)
    waitAndEndSession(browser)
    browser.end()

