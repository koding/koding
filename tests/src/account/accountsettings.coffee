utils   = require '../utils/utils.js'
helpers = require '../helpers/helpers.js'


module.exports =

  editFirstName: (browser) ->

    helpers.beginTest(browser)
    inputSelector = '.firstname input.text'

    helpers.changeName(browser, inputSelector, yes)
    browser.end()


  editLastName: (browser) ->

    helpers.beginTest(browser)
    inputSelector = '.lastname input.text'

    helpers.changeName(browser, inputSelector, no)
    browser.end()
