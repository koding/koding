coffee  = require 'coffee-script/register'
utils   = require '../utils/utils.coffee'
helpers = require '../helpers/helpers.coffee'


module.exports =

  logOut: (browser) ->

    url  = helpers.getUrl()
    user = utils.getUser()

    browser.url(url)

    helpers.doLogin(browser, user)

    helpers.doLogout(browser)

    browser.end()
