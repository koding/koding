helpers = require './helpers.js'
assert  = require 'assert'


module.exports =

  startSession: (browser) ->

    shareButtonSelector = '.status-bar a.share:not(.loading)'

    helpers.beginTest(browser)
    helpers.waitForVMRunning(browser)

    browser
      .waitForElementVisible    shareButtonSelector, 20000
      .element 'css selector', '.status-bar a.share.not-started', (result) =>
          if result.status is 0
            console.log 'session is not started'
            browser
              .click                  shareButtonSelector
              .waitForElementVisible  '.chat-view.onboarding', 20000
              .waitForElementVisible  '.chat-view.onboarding .buttons button.green', 20000
              .click                  '.chat-view.onboarding .buttons button.green'
          else
            console.log 'session is active'

      browser
        .waitForElementVisible  '.message-pane.privatemessage', 20000 # Assertion
        .waitForElementVisible  '.status-bar a.share.active', 20000 # Assertion
