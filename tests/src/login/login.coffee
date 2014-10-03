coffee   = require 'coffee-script/register'
utils    = require '../utils/utils.coffee'
helpers  = require '../helpers/helpers.coffee'

module.exports =

  login: (browser) ->

    user = utils.getUser()
    url  = helpers.getUrl()

    browser.url(url)

    helpers.doLogin(browser, user)

    browser.end()
