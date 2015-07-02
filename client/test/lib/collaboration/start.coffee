helpers = require '../helpers/helpers.js'
utils   = require '../utils/utils.js'
collaborationHelpers = require '../helpers/collaborationhelpers.js'


startSession = (browser, firstUser, secondUser) ->

  secondUserName   = secondUser.username
  secondUserAvatar = ".avatars .avatarview[href='/#{secondUserName}']"
  secondUserOnlineAvatar = secondUserAvatar + '.online'

  helpers.beginTest browser, firstUser
  helpers.waitForVMRunning browser

  collaborationHelpers.startSession browser
  collaborationHelpers.inviteUser   browser, secondUserName

  browser
    .waitForElementVisible secondUserAvatar, 60000
    .waitForElementVisible secondUserOnlineAvatar, 20000
    .end()


joinSession = (browser, firstUser, secondUser) ->

  firstUserName    = firstUser.username
  secondUserName   = secondUser.username
  sharedMachineBox = '[testpath=main-sidebar] .shared-machines'
  shareModal       = '.share-modal'
  fullName         = shareModal + ' .user-details .fullname'
  acceptButton     = shareModal + ' .kdbutton.green'
  rejectButton     = shareModal + ' .kdbutton.red'
  loadingButton    = acceptButton + '.loading'
  selectedMachine  = '.sidebar-machine-box.selected'
  filetree         = '.ide-files-tab'
  chatBox          = '.collaboration.message-pane'
  message          = '.kdlistitemview-activity.privatemessage'
  chatUsers        = chatBox + ' .chat-heads'
  userAvatar       = ".avatars .avatarview.online[href='/#{firstUserName}']"

  helpers.beginTest browser, secondUser

  browser
    .waitForElementVisible     shareModal, 60000
    .waitForElementVisible     fullName, 20000
    .assert.containsText       shareModal, firstUserName
    .waitForElementVisible     acceptButton, 20000
    .waitForElementVisible     rejectButton, 20000
    .click                     acceptButton
    .waitForElementVisible     loadingButton, 20000
    .waitForElementNotPresent  shareModal, 20000
    .waitForElementVisible     selectedMachine, 20000
    .waitForElementVisible     chatBox, 20000
    .waitForElementVisible     chatUsers, 20000
    .waitForElementVisible     message, 20000
    .assert.containsText       chatBox, firstUserName
    .assert.containsText       chatBox, secondUserName
    .assert.containsText       filetree, firstUserName
    .waitForElementVisible     userAvatar, 20000
    .end()


module.exports =

  start: (browser) ->

    firstUser    = utils.getUser no, 0
    secondUser   = utils.getUser no, 1
    firstBrowser = process.env.__NIGHTWATCH_ENV_KEY is 'host_1'

    if firstBrowser
      startSession browser, firstUser, secondUser
    else
      joinSession browser, firstUser, secondUser
