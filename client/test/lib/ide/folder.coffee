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


