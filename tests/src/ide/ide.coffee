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


  createNewFile: (browser) ->

    user = helpers.beginTest(browser)
    helpers.createFile(browser, user)
    browser.end()


  deleteFile: (browser) ->

    user         = helpers.beginTest(browser)
    filename     = helpers.createFile(browser, user)
    webPath      = '/home/' + user.username + '/Web'
    fileSelector = "span[title='" + webPath + '/' + filename + "']"

    browser
      .waitForElementPresent     fileSelector, 20000
      .click                     fileSelector
      .click                     fileSelector + ' + .chevron'
      .waitForElementVisible     'li.delete', 5000
      .click                     'li.delete'
      .waitForElementVisible     '.delete-container', 5000
      .click                     '.delete-container button.clean-red'
      .waitForElementNotPresent  fileSelector, 20000
      .end()


  rename: (browser) ->

    user         = helpers.beginTest(browser)
    filename     = helpers.createFile(browser, user)
    webPath      = '/home/' + user.username + '/Web'
    fileSelector = "span[title='" + webPath + '/' + filename + "']"

    paragraph        = helpers.getFakeText()
    newFileName      = paragraph.split(' ')[0] + '.txt'
    newFileSelector  = "span[title='" + webPath + '/' + newFileName + "']"

    browser
      .waitForElementPresent     fileSelector, 20000
      .click                     fileSelector
      .click                     fileSelector + ' + .chevron'
      .waitForElementVisible     'li.rename', 5000
      .click                     'li.rename'
      .waitForElementVisible     'li.selected .rename-container .hitenterview', 5000
      .clearValue                'li.selected .rename-container .hitenterview'
      .setValue                  'li.selected .rename-container .hitenterview', newFileName + '\n'
      .waitForElementPresent     newFileSelector, 5000 # Assertion
      .end()


  duplicate: (browser) ->

    user          = helpers.beginTest(browser)
    filename      = helpers.createFile(browser, user)
    newFileName   = filename.split('.txt').join('_1.txt')
    webPath       = '/home/' + user.username + '/Web'
    fileSelector  = "span[title='" + webPath + '/' + filename + "']"
    newFile       = "span[title='" + webPath + '/' + newFileName + "']"

    browser
      .waitForElementPresent     fileSelector, 20000
      .click                     fileSelector
      .click                     fileSelector + ' + .chevron'
      .waitForElementVisible     'li.duplicate', 5000
      .click                     'li.duplicate'
      .waitForElementVisible     newFile, 5000 # Assertion
      .end()
