utils    = require '../utils/utils.js'
helpers  = require '../helpers/helpers.js'

module.exports =

  loginWithUsername: (browser) ->

    helpers.beginTest(browser)

    browser.end()
