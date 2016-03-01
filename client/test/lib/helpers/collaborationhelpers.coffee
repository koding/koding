helpers    = require './helpers.js'
assert     = require 'assert'
ideHelpers = require './idehelpers.js'
utils      = require '../utils/utils.js'

messagePane              = '.message-pane.privatemessage'
chatBox                  = '.collaboration.message-pane'
shareButtonSelector      = '.status-bar a.share:not(.loading)'
startedButtonSelector    = '.status-bar a.share.active'
notStartedButtonSelector = '.status-bar a.share.not-started'


module.exports =


  isSessionActive: (browser, callback) ->

    browser
      .waitForElementVisible   shareButtonSelector, 20000
      .pause   4000
      .element 'css selector', notStartedButtonSelector, (result) =>
        isActive = if result.status is 0 then no else yes
        callback(isActive)


  startSession: (browser, readOnlySession) ->

    chatViewSelector      = '.chat-view.onboarding'
    startButtonSelector   = '.chat-view.onboarding .buttons button.start-session'
    readOnlySessionButton = '.chat-settings.active .session-settings .read-only .koding-on-off'

    @isSessionActive browser, (isActive) ->
      if isActive
        console.log ' ✔ Session is active'
      else
        console.log ' ✔ Session is not started'
        browser.click  shareButtonSelector

        if readOnlySession
          browser
            .waitForElementVisible  readOnlySessionButton, 20000
            .waitForElementVisible  "#{readOnlySessionButton}.off", 20000 # Assertion
            .click                  readOnlySessionButton
            .waitForElementVisible  "#{readOnlySessionButton}.on", 20000 # Assertion

        browser
          .waitForElementVisible  chatViewSelector, 20000
          .waitForElementVisible  startButtonSelector, 20000
          .click                  startButtonSelector

      browser
        .waitForElementVisible  startedButtonSelector, 200000 # Assertion


  leaveSessionFromStatusBar: (browser) ->

    @endSessionFromStatusBar(browser, no)


  endSessionFromStatusBar: (browser, shouldAssert = yes) ->

    statusBarSelector       = '.status-bar .collab-status'
    buttonContainerSelector = statusBarSelector + ' .button-container'

    browser
      .waitForElementVisible  startedButtonSelector, 20000
      .click                  startedButtonSelector

    @endSessionModal(browser, shouldAssert)


  endSessionModal: (browser, shouldAssert = yes) ->

    buttonsSelector = '.kdmodal .kdmodal-buttons'

    browser
      .waitForElementVisible  '.with-buttons', 20000
      .waitForElementVisible  buttonsSelector, 20000
      .click                  buttonsSelector + ' button.green'
      .pause                  5000

    if shouldAssert
      browser.waitForElementVisible  notStartedButtonSelector, 20000 # Assertion




    browser
  inviteUser: (browser, username, selectUser = yes) ->

    console.log " ✔ Inviting #{username} to collaboration session"

    chatSelecor = "span.profile[href='/#{username}']"

    browser
      .waitForElementVisible   '.ParticipantHeads-button--new', 20000
      .click                   '.ParticipantHeads-button--new'
      .waitForElementVisible   '.kdautocompletewrapper input', 20000
      .setValue                '.kdautocompletewrapper input', username
      .pause                   5000

    if selectUser
      browser
        .element                 'css selector', chatSelecor, (result) ->
          if result.status is 0
            browser.click        chatSelecor
          else
            browser
              .click             '.ParticipantHeads-button--new'
              .pause             500
              .click             '.ParticipantHeads-button--new'
              .pause             500
              .click             chatSelecor


  closeChatPage: (browser) ->

    closeButtonSelector = '.chat-view a.close span'
    chatBox             = '.chat-view'


    browser.element 'css selector', chatBox, (result) =>
      if result.status is 0
        browser
          .waitForElementVisible     chatBox, 20000
          .waitForElementVisible     closeButtonSelector, 20000
          .click                     closeButtonSelector
          .waitForElementNotVisible  chatBox, 20000
          .waitForElementVisible     '.pane-wrapper .kdsplitview-panel.panel-1', 20000
      else
        browser
          .waitForElementVisible     '.pane-wrapper .kdsplitview-panel.panel-1', 20000


  openChatWindow: (browser) ->

    chatLink = '.status-bar .custom-link-view'
    chatBox  = '.chat-view'

    browser
      .pause 3000
      .waitForElementVisible  chatLink, 20000
      .click                  chatLink
      .waitForElementVisible  chatBox, 20000 # Assertion


  startSessionAndInviteUser: (browser, firstUser, secondUser, assertOnline = yes, readOnlySession = no) ->

    secondUserName         = secondUser.username
    secondUserAvatar       = ".avatars .avatarview[href='/#{secondUserName}']"
    secondUserOnlineAvatar = "#{secondUserAvatar}.online"
    chatTextSelector       = '.status-bar a.active'

    helpers.beginTest browser, firstUser
    helpers.waitForVMRunning browser

    ideHelpers.closeAllTabs(browser)

    @isSessionActive browser, (isActive) =>

      if isActive then browser.end()
      else
        @startSession browser, readOnlySession
        @inviteUser   browser, secondUserName

        browser.waitForElementVisible  secondUserAvatar, 60000

        if assertOnline
          browser.waitForElementVisible  secondUserOnlineAvatar, 50000 # Assertion

        browser
          .waitForElementVisible  chatTextSelector, 50000
          .assert.containsText    chatTextSelector, 'CHAT' # Assertion


  joinSession: (browser, firstUser, secondUser) ->

    firstUserName    = firstUser.username
    secondUserName   = secondUser.username
    sharedMachineBox = '[testpath=main-sidebar] .shared-machines:not(.hidden)'
    shareModal       = '.share-modal'

    fullName         = "#{shareModal} .user-details .fullname"
    acceptButton     = "#{shareModal} .kdbutton.green"
    rejectButton     = "#{shareModal} .kdbutton.red"
    selectedMachine  = '.sidebar-machine-box.selected'
    filetree         = '.ide-files-tab'
    message          = '.kdlistitemview-activity.privatemessage'
    chatUsers        = "#{chatBox} .chat-heads"
    userAvatar       = ".avatars .avatarview.online[href='/#{firstUserName}']"
    chatTextSelector = '.status-bar a.active'
    sessionLoading   = '.session-starting'

    helpers.beginTest browser, secondUser

    browser.element 'css selector', sharedMachineBox, (result) =>

      if result.status is 0 then browser.end()
      else
        browser
          .waitForElementVisible     shareModal, 500000 # wait for vm turn on for host
          .waitForElementVisible     fullName, 50000
          .assert.containsText       shareModal, firstUserName
          .waitForElementVisible     acceptButton, 50000
          .waitForElementVisible     rejectButton, 50000
          .click                     acceptButton
          .waitForElementNotPresent  shareModal, 50000
          .pause                     3000 # wait for sidebar redraw
          .waitForElementVisible     selectedMachine, 50000
          .waitForElementNotPresent  sessionLoading, 50000
          .waitForElementVisible     chatBox, 50000
          .waitForElementVisible     chatUsers, 50000
          .waitForElementVisible     message, 50000
          .assert.containsText       chatBox, firstUserName
          .assert.containsText       chatBox, secondUserName
          .assert.containsText       filetree, firstUserName
          .waitForElementVisible     userAvatar, 50000 # Assertion
          .waitForElementVisible     chatTextSelector, 50000
          .assert.containsText       chatTextSelector, 'CHAT' # Assertion


  waitParticipantLeaveAndEndSession: (browser) ->

    host        = utils.getUser no, 0
    hostBrowser = process.env.__NIGHTWATCH_ENV_KEY is 'host_1'
    participant = utils.getUser no, 1

    participantAvatar = ".avatars .avatarview.online[href='/#{participant.username}']"

    if hostBrowser
      browser.waitForElementNotPresent participantAvatar, 60000
      @endSessionFromStatusBar(browser)


  leaveSession: (browser) ->

    participant  = utils.getUser no, 1
    hostBrowser  = process.env.__NIGHTWATCH_ENV_KEY is 'host_1'

    unless hostBrowser
      @leaveSessionFromStatusBar(browser)
      # assert that no shared vm on sidebar


  initiateCollaborationSession: (browser) ->

    host        = utils.getUser no, 0
    participant = utils.getUser no, 1

    console.log " ✔ Starting collaboration test..."
    console.log " ✔ Host: #{host.username}"
    console.log " ✔ Participant: #{participant.username}"

    hostBrowser = process.env.__NIGHTWATCH_ENV_KEY is 'host_1'

    if hostBrowser
      @startSessionAndInviteUser browser, host, participant
    else
      @joinSession browser, host, participant


  rejectInvitation: (browser) ->

    host        = utils.getUser no, 0
    participant = utils.getUser no, 1

    firstUserName    = host.username
    secondUserName   = participant.username
    sharedMachineBox = '[testpath=main-sidebar] .shared-machines:not(.hidden)'
    shareModal       = '.share-modal'
    fullName         =  "#{shareModal} .user-details .fullname"
    rejectButton     =  "#{shareModal} .kdbutton.red"

    helpers.beginTest browser, participant

    browser.element 'css selector', sharedMachineBox, (result) =>

      if result.status is 0 then browser.end()
      else
        browser
          .waitForElementVisible    shareModal, 500000 # wait for vm turn on for host
          .waitForElementVisible    fullName, 50000
          .assert.containsText      shareModal, firstUserName
          .waitForElementVisible    rejectButton, 50000
          .click                    rejectButton
          .waitForElementNotPresent rejectButton, 20000
          .waitForElementNotPresent shareModal, 20000
          .waitForElementNotPresent sharedMachineBox, 20000


  leaveSessionFromChat: (browser) ->

    participant  = utils.getUser no, 1
    hostBrowser  = process.env.__NIGHTWATCH_ENV_KEY is 'host_1'

    chatBox              = '.chat-view'
    chatBoxChevronButton = "#{chatBox} .general-header span.chevron"
    contextMenu          = '.kdcontextmenu.chat-dropdown'
    leaveSessionMenuItem = "#{contextMenu} .context-list-wrapper li.leave-session"
    kdmodal              = '.kdmodal.kddraggable'
    kdmodalYesButton     = "#{kdmodal} button.green"
    machineSelector      = '.shared-machines'

    unless hostBrowser
      @openChatWindow(browser)

    browser
      .waitForElementVisible     chatBoxChevronButton, 20000
      .click                     chatBoxChevronButton
      .waitForElementVisible     contextMenu, 20000
      .waitForElementVisible     leaveSessionMenuItem, 20000
      .click                     leaveSessionMenuItem
      .waitForElementVisible     kdmodal, 20000
      .click                     kdmodalYesButton
      .waitForElementPresent     machineSelector, 20000
      .waitForElementNotPresent  chatBox,20000


  openMachineSettingsButton: (browser) ->

    sharedMachineSelector       = '.activity-sidebar .shared-machines .sidebar-machine-box .vm.running'
    sharedMachineButtonSettings = "#{sharedMachineSelector} span.settings-icon"
    shareModal                  = '.share-modal'

    browser
      .waitForElementVisible     sharedMachineSelector, 20000
      .moveToElement             sharedMachineSelector, 100, 10
      .waitForElementVisible     sharedMachineButtonSettings, 20000
      .click                     sharedMachineButtonSettings
      .waitForElementVisible     shareModal, 20000


  leaveSessionFromSidebar: (browser) ->

    participant  = utils.getUser no, 1
    hostBrowser  = process.env.__NIGHTWATCH_ENV_KEY is 'host_1'

    shareModal         = '.share-modal'
    leaveSessionButton = "#{shareModal} .kdmodal-inner button.red"
    chatBox            = '.chat-view'
    machineSelector    = '.shared-machines'

    unless hostBrowser
      @openMachineSettingsButton(browser)

    browser
      .waitForElementVisible     leaveSessionButton, 20000
      .click                     leaveSessionButton
      .waitForElementPresent     machineSelector, 20000
      .waitForElementNotPresent  chatBox,20000


  kickUser: (browser, user) ->

    chatHeads     = ".chat-view .chat-heads .ParticipantHeads [href='/#{user.username}']"
    kickSelector  = '.kdcontextmenu .kick'
    menuSelector  = '.kdcontextmenu'

    browser
      .waitForElementVisible     chatHeads, 20000
      .moveToElement             chatHeads, 14,14
      .waitForElementVisible     menuSelector, 20000
      .waitForElementVisible     kickSelector, 20000
      .pause                     3000 # wait for participant
      .click                     kickSelector
      .waitForElementNotPresent  chatHeads, 20000


  assertKicked: (browser) ->

    browser
      .waitForElementVisible  '.kicked-modal', 20000
      .assert.containsText    '.kicked-modal .kdmodal-title', 'Your session has been closed'
      .click                  '.kicked-modal .kdmodal-buttons .button-title'


  # This is not an helper method. It is here because of reusability in tests.
  testLeaveSessionFrom_: (browser, where) ->

    host        = utils.getUser no, 0
    hostBrowser = process.env.__NIGHTWATCH_ENV_KEY is 'host_1'
    participant = utils.getUser no, 1
    chatHeads   = ".chat-view .chat-heads .ParticipantHeads [href='/#{participant.username}']"

    if hostBrowser
      @startSessionAndInviteUser(browser, host, participant)
      browser.waitForElementNotPresent chatHeads, 50000
      @waitParticipantLeaveAndEndSession(browser)
      browser.end()
    else
      @joinSession(browser, host, participant)
      @closeChatPage(browser)

      switch where
        when 'Chat'      then @leaveSessionFromChat(browser)
        when 'Sidebar'   then @leaveSessionFromSidebar(browser)
        when 'StatusBar' then @leaveSessionFromStatusBar(browser)

      browser.end()


  testKickUser_: (browser, hostCallback, participantCallback) ->

    host                   = utils.getUser no, 0
    hostBrowser            = process.env.__NIGHTWATCH_ENV_KEY is 'host_1'
    participant            = utils.getUser no, 1
    secondUserName         = participant.username
    sharedMachineSelector  = '.activity-sidebar .shared-machines .sidebar-machine-box .vm.running'
    informationModal       = '.kdmodal:not(.env-modal)'

    browser.pause 2500, => # wait for user.json creation
      if hostBrowser
        @startSessionAndInviteUser(browser, host, participant)
        @kickUser(browser, participant)

        hostCallback?()

        @closeChatPage(browser)
        @endSessionFromStatusBar(browser)
        browser.end()
      else
        @joinSession(browser, host, participant)
        @assertKicked(browser)

        participantCallback?()

        browser.pause 5000 # wait for host
        browser.end()


  sendMessage: (browser, hostMessage, participantMessage) ->

    host        = utils.getUser no, 0
    hostBrowser = process.env.__NIGHTWATCH_ENV_KEY is 'host_1'
    participant = utils.getUser no, 1

    inputSelector        = '.message-pane .activity-input-widget'
    textAreaSelector     = "#{inputSelector} [testpath=ActivityInputView]"
    messagePaneScroller  = '.message-pane .message-pane-scroller [testpath=activity-list]'
    sendText             = "#{messagePaneScroller} .consequent:not(.join-leave)"
    messagePaneSelector  = '.message-pane'
    hostMessage        or= 'message from host'
    participantMessage or= 'message from participant'

    browser
      .waitForElementVisible   messagePaneSelector, 20000
      .waitForElementVisible   inputSelector, 20000
      .waitForElementVisible   textAreaSelector, 20000

    if hostBrowser
      browser
        .waitForElementVisible messagePaneScroller, 20000
        .setValue              textAreaSelector, hostMessage + '\n'
        .pause                 5000
        .waitForTextToContain  messagePaneScroller, hostMessage
        .waitForTextToContain  messagePaneScroller, participantMessage
    else
      browser
        .waitForElementVisible messagePaneScroller, 20000
        .waitForTextToContain  messagePaneScroller, hostMessage
        .setValue              textAreaSelector, participantMessage + '\n'
        .pause                 5000
        .waitForTextToContain  messagePaneScroller, participantMessage
