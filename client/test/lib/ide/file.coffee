helpers    = require '../helpers/helpers.js'
ideHelpers = require '../helpers/idehelpers.js'

paneSelector = '.pane-wrapper .kdsplitview-panel.panel-1 .application-tab-handle-holder'

module.exports =


  openFile: (browser) ->

    user = helpers.beginTest(browser)
    helpers.waitForVMRunning(browser)
    ideHelpers.openFileFromWebFolder(browser, user)
    browser.end()


  createFileFromContextMenu: (browser) ->

    user = helpers.beginTest(browser)
    helpers.waitForVMRunning(browser)
    helpers.createFile(browser, user)
    browser.end()


  createFileFromMachineHeader: (browser) ->

    user = helpers.beginTest(browser)

    helpers.waitForVMRunning(browser)

    helpers.createFileFromMachineHeader(browser, user)
    browser.end()


  deleteFile: (browser) ->

    user = helpers.beginTest(browser)

    helpers.waitForVMRunning(browser)

    filename     = helpers.createFile(browser, user)
    webPath      = '/home/' + user.username + '/Web'
    fileSelector = "span[title='" + webPath + '/' + filename + "']"

    helpers.deleteFile(browser, fileSelector)
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


  createFileAndOpen: (browser) ->

    user = helpers.beginTest(browser)
    helpers.waitForVMRunning(browser)

    fileName = helpers.createFile(browser, user)
    ideHelpers.openFile(browser, user, fileName)

    browser.end()


  compressFileZip: (browser) ->

    user = helpers.beginTest(browser)
    helpers.waitForVMRunning(browser)

    fileName = helpers.createFile(browser, user)
    ideHelpers.compressFileFolder(browser, user, 'file', fileName, 'zip')

    browser.end()


  compressFileTarGz: (browser) ->

    user = helpers.beginTest(browser)
    helpers.waitForVMRunning(browser)

    fileName = helpers.createFile(browser, user)
    ideHelpers.compressFileFolder(browser, user, 'file', fileName, 'targz')

    browser.end()
