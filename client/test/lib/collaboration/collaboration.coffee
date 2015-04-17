helpers = require '../helpers/helpers.js'
collaborationHelpers = require '../helpers/collaborationhelpers.js'
assert  = require 'assert'


module.exports =


  startSession: (browser) ->

    collaborationHelpers.startSession(browser)
    browser.end()


  endSessionFromStatusBar: (browser) ->

    return browser.end()

    collaborationHelpers.startSession(browser)
    collaborationHelpers.endSessionFromStatusBar(browser)
    browser.end()


  endSessionFromChat: (browser) ->

    return browser.end()

    collaborationHelpers.startSession(browser)
    collaborationHelpers.endSessionFromChat(browser)
    browser.end()
