helpers    = require '../helpers/helpers.js'
ideHelpers = require '../helpers/idehelpers.js'

paneSelector = '.pane-wrapper .kdsplitview-panel.panel-1 .application-tab-handle-holder'

module.exports =


  openFile: (browser) ->

    user = helpers.beginTest(browser)
    helpers.waitForVMRunning(browser)

    helpers.openFolderContextMenu(browser, user, 'Web')

    webPath       = '/home/' + user.username + '/Web'
    indexSelector = "span[title='" + webPath + '/index.html' + "']"

    browser
      .waitForElementVisible   'li.expand', 15000
      .click                   'li.expand'
      .waitForElementVisible   indexSelector, 15000
      .click                   indexSelector
      .click                   indexSelector + ' + .chevron'
      .waitForElementVisible   'li.open-file', 20000
      .click                   'li.open-file'
      .waitForElementVisible   '.indexhtml', 20000 # Assertion
      .waitForElementVisible   '.kdtabpaneview.indexhtml', 20000 # Assertion
      .assert.containsText     '.kdtabpaneview.indexhtml', 'Hello World from HTML by Koding' # Assertion
      .end()


  createFileFromContextMenu: (browser) ->

    user = helpers.beginTest(browser)
    helpers.waitForVMRunning(browser)
    helpers.createFile(browser, user)
    browser.end()


  createFileFromMachineHeader: (browser) ->

    user = helpers.beginTest(browser)

    helpers.waitForVMRunning(browser)

    filePath      = '/home/' + user.username
    paragraph     = helpers.getFakeText()
    fileName      = paragraph.split(' ')[0] + '.txt'
    fileSelector  = "span[title='" + filePath + '/' + fileName + "']"
    inputSelector = '.rename-container input.hitenterview'

    browser
      .waitForElementVisible     '.vm-header', 20000
      .click                     '.vm-header span.chevron'
      .waitForElementVisible     '.context-list-wrapper', 20000
      .click                     '.context-list-wrapper li.new-file'
      .waitForElementVisible     inputSelector, 20000
      .click                     inputSelector
      .clearValue                inputSelector
      .setValue                  inputSelector, fileName + '\n'
      .waitForElementPresent     fileSelector, 20000 # Assertion
      .end()


  createFolderMachineHeader: (browser) ->

    user = helpers.beginTest(browser)
    helpers.waitForVMRunning(browser)
    helpers.createFolder(browser, user)
    browser.end()


  createFolderFromContextMenu: (browser) ->

    user = helpers.beginTest(browser)
    helpers.waitForVMRunning(browser)
    helpers.createFile(browser, user, 'li.new-folder')
    browser.end()


  deleteFile: (browser) ->

    user = helpers.beginTest(browser)

    helpers.waitForVMRunning(browser)

    filename     = helpers.createFile(browser, user)
    webPath      = '/home/' + user.username + '/Web'
    fileSelector = "span[title='" + webPath + '/' + filename + "']"

    helpers.deleteFile(browser, fileSelector)
    browser.end()


  deleteFolder: (browser) ->

    user = helpers.beginTest(browser)

    helpers.waitForVMRunning(browser)

    folderData = helpers.createFolder(browser, user)
    webPath    = '/home/' + user.username
    selector   = "span[title='" + webPath + '/' + folderData.name + "']"

    helpers.deleteFile(browser, folderData.selector)
    browser.end()


  renameFile: (browser) ->

    user = helpers.beginTest(browser)

    helpers.waitForVMRunning(browser)

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
      .waitForElementVisible     'li.rename', 20000
      .click                     'li.rename'
      .waitForElementVisible     'li.selected .rename-container .hitenterview', 20000
      .clearValue                'li.selected .rename-container .hitenterview'
      .setValue                  'li.selected .rename-container .hitenterview', newFileName + '\n'
      .waitForElementPresent     newFileSelector, 20000 # Assertion
      .end()


  duplicateFile: (browser) ->

    user = helpers.beginTest(browser)

    helpers.waitForVMRunning(browser)

    filename      = helpers.createFile(browser, user)
    newFileName   = filename.split('.txt').join('_1.txt')
    webPath       = '/home/' + user.username + '/Web'
    fileSelector  = "span[title='" + webPath + '/' + filename + "']"
    newFile       = "span[title='" + webPath + '/' + newFileName + "']"

    browser
      .waitForElementPresent     fileSelector, 20000
      .click                     fileSelector
      .click                     fileSelector + ' + .chevron'
      .waitForElementPresent     'li.duplicate', 20000
      .click                     'li.duplicate'
      .pause                     2000
      .waitForElementPresent     newFile, 20000 # Assertion

    helpers.deleteFile(browser, fileSelector)
    helpers.deleteFile(browser, newFile)

    browser.end()
