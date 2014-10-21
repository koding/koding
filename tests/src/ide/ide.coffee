utils   = require '../utils/utils.js'
helpers = require '../helpers/helpers.js'
faker   = require 'faker'
assert  = require 'assert'


module.exports =


  openFile: (browser) ->

    user = helpers.beginTest(browser)

    helpers.openFolderContextMenu(browser, user, 'Web')

    webPath       = '/home/' + user.username + '/Web'
    indexSelector = "span[title='" + webPath + '/index.html' + "']"

    browser
      .waitForElementVisible   'li.expand', 15000
      .click                   'li.expand'
      .waitForElementVisible   indexSelector, 15000
      .click                   indexSelector
      .click                   indexSelector + ' + .chevron'
      .waitForElementVisible   'li.open-file', 5000
      .click                   'li.open-file'
      .waitForElementVisible   '.indexhtml',   5000 # Assertion
      .waitForElementVisible   '.ace_content', 5000 # Assertion
      .assert.containsText     '.ace_content', 'Hello World from HTML by Koding' # Assertion
      .end()
