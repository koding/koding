helpers = require './helpers.js'
assert  = require 'assert'

messagePane = '.message-pane.privatemessage'
notStartedButtonSelector = '.status-bar a.share.not-started'

module.exports =

  isSessionActive: (browser, callback) ->

    shareButtonSelector = '.status-bar a.share:not(.loading)'

    browser
      .waitForElementVisible   shareButtonSelector, 20000
      .pause   4000
      .element 'css selector', notStartedButtonSelector, (result) =>
        isActive = if result.status is 0 then no else yes
        callback(isActive)


  startSession: (browser) ->

    shareButtonSelector = '.status-bar a.share:not(.loading)'
    chatViewSelector    = '.chat-view.onboarding'
    startButtonSelector = '.chat-view.onboarding .buttons button.start-session'

    @isSessionActive browser, (isActive) ->
      if isActive
        console.log ' ✔ Session is active'
      else
        console.log ' ✔ Session is not started'
        browser
          .click                  shareButtonSelector
          .waitForElementVisible  chatViewSelector, 20000
          .waitForElementVisible  startButtonSelector, 20000
          .click                  startButtonSelector

      browser
        .waitForElementVisible  messagePane, 200000 # Assertion
        .waitForElementVisible  '.status-bar a.share.active', 20000 # Assertion


  leaveSessionFromStatusBar: (browser) ->

    @endSessionFromStatusBar(browser, no)


  endSessionFromStatusBar: (browser, shouldAssert = yes) ->

    statusBarSelector       = '.status-bar .collab-status'
    buttonContainerSelector = statusBarSelector + ' .button-container'

    browser
      .waitForElementVisible  statusBarSelector, 20000
      .waitForElementVisible  statusBarSelector + ' span', 20000
      .click                  statusBarSelector + ' span'
      .waitForElementVisible  buttonContainerSelector, 20000
      .click                  buttonContainerSelector + ' button.end-session'

    @endSessionModal(browser, shouldAssert)


  endSessionFromChat: (browser) ->

    @openChatSettingsMenu(browser)

    browser
      .waitForElementVisible  '.chat-dropdown li.end-session', 20000
      .click                  '.chat-dropdown li.end-session'

    @endSessionModal(browser)


  endSessionModal: (browser, shouldAssert = yes) ->

    buttonsSelector = '.kdmodal .kdmodal-buttons'

    browser
      .waitForElementVisible  '.with-buttons', 20000
      .waitForElementVisible  buttonsSelector, 20000
      .click                  buttonsSelector + ' button.green'
      .pause                  5000

    if shouldAssert
      browser.waitForElementVisible  notStartedButtonSelector, 20000 # Assertion


  openChatSettingsMenu: (browser) ->

    chatSettingsIcon = messagePane + ' .general-header .chat-dropdown .chevron'

    browser
      .waitForElementVisible  messagePane, 20000
      .waitForElementVisible  messagePane + ' .general-header', 20000
      .click                  messagePane + ' .general-header'
      .waitForElementVisible  chatSettingsIcon, 20000
      .click                  chatSettingsIcon


  inviteUser: (browser, username) ->

    console.log " ✔ Inviting #{username} to collaboration session"

    chatSelecor = "span.profile[href='/#{username}']"

    browser
      .waitForElementVisible   '.ParticipantHeads-button--new', 20000
      .click                   '.ParticipantHeads-button--new'
      .waitForElementVisible   '.kdautocompletewrapper input', 20000
      .setValue                '.kdautocompletewrapper input', username
      .pause                   5000
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