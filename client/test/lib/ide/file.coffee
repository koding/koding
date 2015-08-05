helpers    = require '../helpers/helpers.js'
ideHelpers = require '../helpers/idehelpers.js'

paneSelector = '.pane-wrapper .kdsplitview-panel.panel-1 .application-tab-handle-holder'

module.exports =


  # openFile: (browser) ->

  #   user = helpers.beginTest(browser)
  #   helpers.waitForVMRunning(browser)

  #   helpers.openFolderContextMenu(browser, user, 'Web')

  #   webPath       = '/home/' + user.username + '/Web'
  #   indexSelector = "span[title='" + webPath + '/index.html' + "']"

  #   browser
  #     .waitForElementVisible   'li.expand', 15000
  #     .click                   'li.expand'
  #     .waitForElementVisible   indexSelector, 15000
  #     .click                   indexSelector
  #     .click                   indexSelector + ' + .chevron'
  #     .waitForElementVisible   'li.open-file', 20000
  #     .click                   'li.open-file'
  #     .waitForElementVisible   '.pane-wrapper .kdsplitview-panel .indexhtml', 20000 # Assertion
  #     .waitForElementVisible   '.kdtabpaneview.indexhtml', 20000 # Assertion
  #     .assert.containsText     '.kdtabpaneview.indexhtml', 'Hello World from HTML by Koding' # Assertion
  #     .end()


  # createFileFromContextMenu: (browser) ->

  #   user = helpers.beginTest(browser)
  #   helpers.waitForVMRunning(browser)
  #   helpers.createFile(browser, user)
  #   browser.end()


  # createFileFromMachineHeader: (browser) ->

  #   user = helpers.beginTest(browser)

  #   helpers.waitForVMRunning(browser)

  #   helpers.createFileFromMachineHeader(browser, user)
  #   browser.end()


  # deleteFile: (browser) ->

  #   user = helpers.beginTest(browser)

  #   helpers.waitForVMRunning(browser)

  #   filename     = helpers.createFile(browser, user)
  #   webPath      = '/home/' + user.username + '/Web'
  #   fileSelector = "span[title='" + webPath + '/' + filename + "']"

  #   helpers.deleteFile(browser, fileSelector)
  #   browser.end()


  # renameFile: (browser) ->

  #   user = helpers.beginTest(browser)

  #   helpers.waitForVMRunning(browser)

  #   filename     = helpers.createFile(browser, user)
  #   webPath      = '/home/' + user.username + '/Web'
  #   fileSelector = "span[title='" + webPath + '/' + filename + "']"

  #   paragraph        = helpers.getFakeText()
  #   newFileName      = paragraph.split(' ')[0] + '.txt'
  #   newFileSelector  = "span[title='" + webPath + '/' + newFileName + "']"

  #   browser
  #     .waitForElementPresent     fileSelector, 20000
  #     .click                     fileSelector
  #     .click                     fileSelector + ' + .chevron'
  #     .waitForElementVisible     'li.rename', 20000
  #     .click                     'li.rename'
  #     .waitForElementVisible     'li.selected .rename-container .hitenterview', 20000
  #     .clearValue                'li.selected .rename-container .hitenterview'
  #     .setValue                  'li.selected .rename-container .hitenterview', newFileName + '\n'
  #     .waitForElementPresent     newFileSelector, 20000 # Assertion
  #     .end()


  # duplicateFile: (browser) ->

  #   user = helpers.beginTest(browser)

  #   helpers.waitForVMRunning(browser)

  #   filename      = helpers.createFile(browser, user)
  #   newFileName   = filename.split('.txt').join('_1.txt')
  #   webPath       = '/home/' + user.username + '/Web'
  #   fileSelector  = "span[title='" + webPath + '/' + filename + "']"
  #   newFile       = "span[title='" + webPath + '/' + newFileName + "']"

  #   browser
  #     .waitForElementPresent     fileSelector, 20000
  #     .click                     fileSelector
  #     .click                     fileSelector + ' + .chevron'
  #     .waitForElementPresent     'li.duplicate', 20000
  #     .click                     'li.duplicate'
  #     .pause                     2000
  #     .waitForElementPresent     newFile, 20000 # Assertion

  #   helpers.deleteFile(browser, fileSelector)
  #   helpers.deleteFile(browser, newFile)

  #   browser.end()


  # createFileAndOpen: (browser) ->

  #   user = helpers.beginTest(browser)
  #   helpers.waitForVMRunning(browser)

  #   fileName = helpers.createFile(browser, user)
  #   ideHelpers.openFile(browser, user, fileName)

  #   browser.end()

  cancelSaveFile: (browser) ->

    dummyText = helpers.getFakeText().split(' ')[0]
    closeFileSelector = "#{paneSelector} span.close-tab"
    cancelSelector = '.modal-with-text .kdmodal-inner button.light-gray'

    user = helpers.beginTest(browser)
    helpers.waitForVMRunning(browser)

    fileName = helpers.createFile(browser, user)

    ideHelpers.openFile(browser, user, fileName)
    ideHelpers.setTextToEditor(browser, dummyText)

    browser
      .moveToElement             paneSelector, 60, 15
      .waitForElementVisible     closeFileSelector, 20000
      .click                     closeFileSelector
      .waitForElementVisible  cancelSelector, 20000
      .assert.containsText  cancelSelector + ' span.button-title', 'CANCEL'
      .click  cancelSelector

    ideHelpers.setTextToEditor(browser, '')
    ideHelpers.closeFile(browser, fileName)

    browser.end()

  dontSaveFile: (browser) ->

    dummyText = helpers.getFakeText().split(' ')[0]
    closeFileSelector = "#{paneSelector} span.close-tab"
    dontSaveSelector = '.modal-with-text .kdmodal-inner button.red'

    user = helpers.beginTest(browser)
    helpers.waitForVMRunning(browser)

    fileName = helpers.createFile(browser, user)

    ideHelpers.openFile(browser, user, fileName)
    ideHelpers.setTextToEditor(browser, dummyText)

    browser
      .moveToElement             paneSelector, 60, 15
      .waitForElementVisible     closeFileSelector, 20000
      .click                     closeFileSelector
      .waitForElementVisible  dontSaveSelector, 20000
      .assert.containsText  dontSaveSelector + ' span.button-title', 'DON\'T SAVE'
      .click  dontSaveSelector
      .end()

  saveCloseFile: (browser) ->

    dummyText = helpers.getFakeText().split(' ')[0]
    closeFileSelector = "#{paneSelector} span.close-tab"
    saveCloseSelector = '.modal-with-text .kdmodal-inner button.green'

    filesTabSelector    = '.ide-files-tab .file-container'
    saveAsModalSelector = '.save-as-dialog'
    saveAsInputSelector = "#{saveAsModalSelector} input[type=text]"
    newName             = helpers.getFakeText().split(' ')[0] + '.txt'

    saveButtonSelector  = "#{saveAsModalSelector} .kddialog-buttons span.button-title"

    user = helpers.beginTest(browser)
    helpers.waitForVMRunning(browser)

    ideHelpers.openNewFile(browser)
    ideHelpers.setTextToEditor(browser, dummyText)

    browser
      .moveToElement             paneSelector, 60, 15
      .waitForElementVisible     closeFileSelector, 20000
      .click                     closeFileSelector
      .waitForElementVisible  saveCloseSelector, 20000
      .assert.containsText  saveCloseSelector + ' span.button-title', 'SAVE AND CLOSE'
      .click  saveCloseSelector
      .waitForElementVisible  saveAsModalSelector, 20000
      .waitForElementVisible  saveAsInputSelector, 20000
      .clearValue             saveAsInputSelector
      .setValue               saveAsInputSelector, newName
      .click                  saveButtonSelector
      .waitForElementVisible  filesTabSelector, 20000
      .pause  20000
      .assert.containsText    filesTabSelector, newName # Assertion

    ideHelpers.openAnExistingFile(browser, user, newName, dummyText)

    browser.end()
