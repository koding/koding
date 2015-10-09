helpers = require '../helpers/helpers.js'
utils   = require '../utils/utils.js'
collaborationHelpers = require '../helpers/collaborationhelpers.js'

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
  hostBrowser = process.env.__NIGHTWATCH_ENV_KEY is 'host_1'

  if hostBrowser
    startSession browser, host, participant
  else
    joinSession browser, host, participant


module.exports =


  start: (browser) ->

    start(browser)

    browser.end()


  runCommandOnInviteUserTerminal: (browser) ->

    start(browser)

    collaborationHelpers.closeChatPage(browser)

    helpers.runCommandOnTerminal(browser)

    browser.end()



