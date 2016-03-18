helpers    = require './helpers.js'
assert     = require 'assert'
ideHelpers = require './idehelpers.js'
utils      = require '../utils/utils.js'

startButtonSelector = '.IDE-StatusBar .share.not-started button'
endButtonSelector   = '.IDE-StatusBar .share.active button'
collabLink          = '.collaboration-link'


module.exports =


  isSessionActive: (browser, callback) ->

    browser
      .pause   5000
      .element 'css selector', startButtonSelector, (result) ->
        isActive = if result.status is 0 then no else yes
        callback isActive


  startSession: (browser) ->

    @isSessionActive browser, (isActive) ->
      if isActive
        console.log ' ✔ Session is active'
      else
        console.log ' ✔ Session is not started'
        browser.click  startButtonSelector

        browser
          .waitForElementVisible  startButtonSelector, 20000
          .click                  startButtonSelector
          .waitForElementVisible  endButtonSelector, 200000 # Assertion


  leaveSessionFromStatusBar: (browser) -> @endSessionFromStatusBar(browser, no)


  endSessionFromStatusBar: (browser, shouldAssert = yes) ->

    browser
      .waitForElementVisible  endButtonSelector, 20000
      .click                  endButtonSelector

    @endSessionModal(browser, shouldAssert)


  endSessionModal: (browser, shouldAssert = yes) ->

    buttonsSelector = '.kdmodal .kdmodal-buttons'

    browser
      .waitForElementVisible  '.with-buttons', 20000
      .waitForElementVisible  buttonsSelector, 20000
      .click                  buttonsSelector + ' button.green'
      .pause                  5000

    if shouldAssert
      browser.waitForElementVisible  startButtonSelector, 20000 # Assertion


  startSessionAndInviteUser: (browser, firstUser, secondUser, callback, skipLogin = no) ->

    secondUserAvatar       = ".avatars .avatarview[href='/#{secondUser.username}']"
    secondUserOnlineAvatar = "#{secondUserAvatar}.online"

    unless skipLogin
      helpers.beginTest browser, firstUser
      helpers.waitForVMRunning browser

      ideHelpers.closeAllTabs(browser)

    @isSessionActive browser, (isActive) =>

      if isActive
        @endSessionFromStatusBar(browser)
        browser.pause 5000

      @startSession browser

      browser
        .waitForElementVisible  endButtonSelector, 50000
        .assert.containsText    endButtonSelector, 'END COLLABORATION' # Assertion
        .getText                collabLink, (result) ->
          console.log ' ✔ Collaboration link is ', result.value
          browser.writeCollabLink result.value, ->
            browser
              .waitForElementVisible secondUserAvatar, 60000
              .waitForElementVisible secondUserOnlineAvatar, 50000 # Assertion

            callback?()


  joinSession: (browser, firstUser, secondUser, callback) ->

    firstUserName    = firstUser.username
    shareModal       = '.share-modal'
    fullName         = "#{shareModal} .user-details .fullname"
    acceptButton     = "#{shareModal} .kdbutton.green"
    rejectButton     = "#{shareModal} .kdbutton.red"
    selectedMachine  = '.sidebar-machine-box.selected'
    filetree         = '.ide-files-tab'
    sessionLoading   = '.session-starting'

    console.log ' ✔ Getting collaboration link...'

    helpers.beginTest browser, secondUser
    browser.getCollabLink browser, (url) ->
      console.log '>>>>>>>>>> Participant get the link', url

      browser
        .url                       url
        .pause                     5000 # sidebar redraw
        .waitForElementVisible     shareModal, 500000 # wait for vm turn on for host
        .waitForElementVisible     fullName, 50000
        .waitForTextToContain      shareModal, firstUserName
        .waitForElementVisible     acceptButton, 50000
        .waitForElementVisible     rejectButton, 50000
        .click                     acceptButton
        .waitForElementNotPresent  shareModal, 50000
        .pause                     3000 # wait for sidebar redraw
        .waitForElementVisible     selectedMachine, 50000
        .waitForElementNotPresent  sessionLoading, 50000
        .waitForElementVisible     filetree, 50000
        .waitForTextToContain      filetree, firstUserName
        .waitForElementVisible     endButtonSelector, 50000
        .assert.containsText       endButtonSelector, 'LEAVE SESSION' # Assertion

      callback?()


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


  initiateCollaborationSession: (browser, hostCallback, participantCallback) ->

    host        = utils.getUser no, 0
    participant = utils.getUser no, 1

    console.log ' ✔ Starting collaboration test...'
    console.log " ✔ Host: #{host.username}"
    console.log " ✔ Participant: #{participant.username}"

    hostBrowser = process.env.__NIGHTWATCH_ENV_KEY is 'host_1'

    if hostBrowser
      @startSessionAndInviteUser browser, host, participant, hostCallback
    else
      @joinSession browser, host, participant, participantCallback


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

    hostBrowser        = process.env.__NIGHTWATCH_ENV_KEY is 'host_1'
    shareModal         = '.share-modal'
    leaveSessionButton = "#{shareModal} .kdmodal-inner button.red"
    machineSelector    = '.shared-machines'

    unless hostBrowser
      @openMachineSettingsButton(browser)

    browser
      .waitForElementVisible     leaveSessionButton, 20000
      .click                     leaveSessionButton
      .waitForElementNotVisible  machineSelector, 20000
      .pause                     1500 # wait little bit before leaving


  kickUser: (browser, user) ->

    chatHeads     = ".chat-view .chat-heads .ParticipantHeads [href='/#{user.username}']"
    kickSelector  = '.kdcontextmenu .kick'
    menuSelector  = '.kdcontextmenu'

    browser
      .waitForElementVisible     chatHeads, 20000
      .moveToElement             chatHeads, 14, 14
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


  requestPermission: (browser, waitForApproval = yes) ->

    finderPane       = '.kdtabpaneview.files .file-container'
    notificationView = '.system-notification.ide-warning-view.in'
    permissionLink   = "#{notificationView} .ask-permission"
    deniedView       = "#{notificationView}.error"
    acceptedView     = "#{notificationView}.success"

    browser
      .waitForElementVisible        finderPane, 20000
      .click                        finderPane
      .waitForElementVisible        notificationView, 20000
      .pause                        500 # wait for animation
      .waitForElementVisible        permissionLink, 20000
      .click                        permissionLink
      .waitForElementNotPresent     notificationView, 20000

    if waitForApproval
      browser.waitForElementVisible acceptedView, 20000
    else
      browser.waitForElementVisible deniedView, 20000


  answerPermissionRequest: (browser, shouldAccept = yes) ->

    contextMenu = '.IDE-StatusBarContextMenu'
    denyLink    = "#{contextMenu} .permission-row .deny"
    acceptLink  = "#{contextMenu} .permission-row .grant"

    browser
      .waitForElementVisible contextMenu, 20000
      .waitForElementVisible denyLink, 20000
      .waitForElementVisible acceptLink, 20000

    if shouldAccept
      browser.click acceptLink
    else
      browser.click denyLink

    browser.waitForElementNotPresent contextMenu, 20000


  # This is not an helper method. It is here because of reusability in tests.
  testLeaveSessionFrom_: (browser, where) ->

    browser.pause 2500, => # wait for user.json creation

      hostCallback = =>

        @waitParticipantLeaveAndEndSession(browser)
        browser.end()


      participantCallback = =>

        switch where
          when 'Sidebar'   then @leaveSessionFromSidebar(browser)
          when 'StatusBar' then @leaveSessionFromStatusBar(browser)

        browser.end()

      @initiateCollaborationSession(browser, hostCallback, participantCallback)


  testKickUser_: (browser, hostCallback, participantCallback) ->

    host                   = utils.getUser no, 0
    hostBrowser            = process.env.__NIGHTWATCH_ENV_KEY is 'host_1'
    participant            = utils.getUser no, 1
    sharedMachineSelector  = '.activity-sidebar .shared-machines .sidebar-machine-box .vm.running'

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
