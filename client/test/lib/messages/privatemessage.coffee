helpers = require '../helpers/helpers.js'
assert  = require 'assert'
messagesHelpers = require '../helpers/messageshelpers.js'


module.exports =


  startConversation: (browser) ->

    messageUser =
      userName  : 'devrim'
      fullName  : 'Devrim Yasar'

    helpers.beginTest(browser)

    messagesHelpers.startConversation(browser, messageUser)
    browser.end()

    helpers.beginTest(browser)

