utils   = require '../utils/utils.js'
helpers = require '../helpers/helpers.js'


module.exports =

  logOut: (browser) ->

    url  = helpers.getUrl()
    user = utils.getUser()

    browser.url(url)

    helpers.doLogin(browser, user)

    helpers.doLogout(browser)

    browser.end()
