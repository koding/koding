utils    = require '../utils/utils.js'
helpers  = require '../helpers/helpers.js'

module.exports =

  login: (browser) ->

    user = utils.getUser()
    url  = helpers.getUrl()

    browser.url(url)

    helpers.doLogin(browser, user)

    browser.end()
