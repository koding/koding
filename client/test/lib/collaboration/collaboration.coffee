helpers = require '../helpers/helpers.js'
collaborationHelpers = require '../helpers/collaborationhelpers.js'
assert  = require 'assert'


module.exports =


  startSession: (browser) ->

    collaborationHelpers.startSession(browser)
    browser.end()



