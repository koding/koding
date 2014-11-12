utils = require '../utils/utils.js'
helpers = require '../helpers/helpers.js'


module.exports =

  registerUser: (browser) ->

    helpers.doRegister(browser)

    browser.end()
