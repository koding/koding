helpers = require '../helpers/helpers.js'

module.exports =

  runUnitTests: (browser) ->

    helpers.beginTest(browser)

    browser
      .url                      "#{helpers.getUrl()}/TestRunner"
      .waitForElementVisible    '#mocha', 20000
      .waitForElementVisible    '#tests-completed', 20000
      .waitForElementNotPresent '.test.fail', 1000
      .end()
