utils    = require '../utils/utils.js'
helpers  = require '../helpers/helpers.js'

module.exports =

  login: (browser) ->

    helpers.beginTest(browser)

    browser.end()
