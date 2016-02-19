helpers    = require './helpers.js'
assert     = require 'assert'
ideHelpers = require './idehelpers.js'
utils      = require '../utils/utils.js'

messagePane              = '.message-pane.privatemessage'
chatBox                  = '.collaboration.message-pane'
shareButtonSelector      = '.status-bar a.share:not(.loading):not(.appear-in-button)'
startedButtonSelector    = '.status-bar a.share.active'
notStartedButtonSelector = '.status-bar a.share.not-started'
collabLink               = '.collaboration-link'


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


  startSessionAndInviteUser: (browser, firstUser, secondUser, assertOnline = yes, readOnlySession = no) ->

    helpers.beginTest browser, firstUser
    helpers.waitForVMRunning browser

    ideHelpers.closeAllTabs(browser)

    @startSessionAndInviteUser_(browser, firstUser, secondUser, assertOnline, readOnlySession)


  startSessionAndInviteUser_: (browser, firstUser, secondUser, assertOnline, readOnlySession) ->

    secondUserAvatar       = ".avatars .avatarview[href='/#{secondUser.username}']"
    secondUserOnlineAvatar = "#{secondUserAvatar}.online"

    @isSessionActive browser, (isActive) =>

      if isActive then browser.end()
      else
        @startSession browser, readOnlySession

        browser
          .waitForElementVisible  startedButtonSelector, 50000
          .assert.containsText    startedButtonSelector, 'END COLLABORATION' # Assertion
          .getText                collabLink, (result) ->
            console.log ' ✔ Collaboration link is ', result.value
            browser.writeCollabLink result.value, ->
              browser.waitForElementVisible secondUserAvatar, 60000

              if assertOnline
                browser.waitForElementVisible secondUserOnlineAvatar, 50000 # Assertion


  joinSession: (browser, firstUser, secondUser, join = yes) ->

    firstUserName    = firstUser.username
    secondUserName   = secondUser.username
    sharedMachineBox = '[testpath=main-sidebar] .shared-machines:not(.hidden)'
    shareModal       = '.share-modal'
    fullName         = "#{shareModal} .user-details .fullname"
    acceptButton     = "#{shareModal} .kdbutton.green"
    rejectButton     = "#{shareModal} .kdbutton.red"
    selectedMachine  = '.sidebar-machine-box.selected'
    filetree         = '.ide-files-tab'
    chatUsers        = "#{chatBox} .chat-heads"
    userAvatar       = ".avatars .avatarview.online[href='/#{firstUserName}']"
    sessionLoading   = '.session-starting'

    console.log ' ✔ Getting collaboration link...'

    helpers.beginTest browser, secondUser
    browser.getCollabLink (url) =>

      browser.url url
      browser.element 'css selector', sharedMachineBox, (result) =>

        if result.status is 0
          return browser.end()

        if join
          browser
            .pause                     5000 # sidebar redraw
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
            .assert.containsText       filetree, firstUserName
            .waitForElementVisible     shareButtonSelector, 50000
            .assert.containsText       shareButtonSelector, 'LEAVE SESSION' # Assertion
        else
          @rejectInvitation(browser)


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


  initiateCollaborationSession: (browser, join = yes) ->

    host        = utils.getUser no, 0
    participant = utils.getUser no, 1

    console.log " ✔ Starting collaboration test..."
    console.log " ✔ Host: #{host.username}"
    console.log " ✔ Participant: #{participant.username}"

    hostBrowser = process.env.__NIGHTWATCH_ENV_KEY is 'host_1'

    if hostBrowser
      @startSessionAndInviteUser browser, host, participant
    else
      @joinSession browser, host, participant, join


  rejectInvitation: (browser) ->

    host             = utils.getUser no, 0
    participant      = utils.getUser no, 1
    firstUserName    = host.username
    sharedMachineBox = '[testpath=main-sidebar] .shared-machines:not(.hidden)'
    shareModal       = '.share-modal'
    fullName         =  "#{shareModal} .user-details .fullname"
    rejectButton     =  "#{shareModal} .kdbutton.red"

    browser
      .pause                    5000 # wait for sidebar
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

    browser.pause 2500, => # wait for user.json creation

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
