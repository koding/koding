utils = require '../utils/utils.js'


module.exports =

  registerUser: (browser, user) ->

    helpers = require '../helpers/helpers.js'

    helpers.doRegister(browser, user)

    browser.end()
