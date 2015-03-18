helpers = require '../helpers/helpers.js'


module.exports =

  logOut: (browser) ->

    helpers.beginTest(browser)

    helpers.doLogout(browser)

    browser.end()
