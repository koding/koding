helpers    = require '../helpers/helpers.js'
ideHelpers = require '../helpers/idehelpers.js'

module.exports =


  createFolderFromMachineHeader: (browser) ->

    user = helpers.beginTest(browser)
    helpers.waitForVMRunning(browser)
    helpers.createFolder(browser, user)
    browser.end()


  saveFileToFolder: (browser) ->

    user = helpers.beginTest(browser)
    helpers.waitForVMRunning(browser)
    folderData = helpers.createFolder(browser, user)

    helpers.createFile(browser, user, 'li.new-file', folderData.name)
    browser.end()


   createFolderFromContextMenu: (browser) ->

    user = helpers.beginTest(browser)
    helpers.waitForVMRunning(browser)
    helpers.createFile(browser, user, 'li.new-folder')
    browser.end()


  deleteFolder: (browser) ->

    user = helpers.beginTest(browser)

    helpers.waitForVMRunning(browser)

    folderData = helpers.createFolder(browser, user)
    webPath    = '/home/' + user.username
    selector   = "span[title='" + webPath + '/' + folderData.name + "']"

    helpers.deleteFile(browser, folderData.selector)
    browser.end()


  terminalFromHereFolder: (browser) ->

    user = helpers.beginTest(browser)
    helpers.waitForVMRunning(browser)

    folderName = 'Web'
    folderPath = "/home/#{user.username}/#{folderName}"
    terminalTextAssertSelector = '.application-tabview .terminal.active .terminal-pane'

    helpers.openFolderContextMenu(browser, user, folderName)

    browser
      .waitForElementVisible  '.context-list-wrapper .terminal-from-here', 20000
      .click                  '.context-list-wrapper .terminal-from-here'
      .pause 6000 # required for the Connecting...
      .assert.containsText     terminalTextAssertSelector, folderPath # Assertion
      .end()


  compressFolderZip: (browser) ->

    user = helpers.beginTest(browser)
    helpers.waitForVMRunning(browser)

    folderName = helpers.createFolder(browser, user)
    ideHelpers.compressFileFolder(browser, user, 'folder', folderName, 'zip')

    browser.end()


  compressFolderTarGz: (browser) ->

    user = helpers.beginTest(browser)
    helpers.waitForVMRunning(browser)

    folderName = helpers.createFolder(browser, user)
    ideHelpers.compressFileFolder(browser, user, 'folder', folderName, 'targz')

    browser.end()
