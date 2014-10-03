coffee  = require 'coffee-script/register'
utils   = require '../utils/utils.coffee'


module.exports =

  registerUser: (browser, user) ->

    helpers = require '../helpers/helpers.coffee'

    helpers.doRegister(browser, user)

    browser.end()
