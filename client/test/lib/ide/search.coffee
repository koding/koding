helpers    = require '../helpers/helpers.js'
ideHelpers = require '../helpers/idehelpers.js'

paneSelector = '.pane-wrapper .kdsplitview-panel.panel-1 .application-tab-handle-holder'

module.exports =


  findInFiles: (browser) ->

    helpers.beginTest(browser)
    helpers.waitForVMRunning(browser)

    contentSearchModalSelector  = '.content-search-modal'
    findInFilesSelector         = '.kdlistview-contextmenu li.search-in-all-files'
    matchedWordSelector         = '.content-search-result pre p.match'
    activeUntitledFileSelector  = "#{paneSelector} .untitledtxt.active"
    activeEditorSelector        = '.pane-wrapper .kdsplitview-panel.panel-1 .kdtabpaneview.active .ace_content'
    fileNameSelector            = '.content-search-result .filename:first-child'

    ideHelpers.openNewFile(browser)
    ideHelpers.openContextMenu(browser)

    browser
      .waitForElementVisible     findInFilesSelector, 20000
      .click                     findInFilesSelector
      .waitForElementVisible     contentSearchModalSelector, 20000
      .setValue                  contentSearchModalSelector + ' input[name=findInput]', 'hello'
      .click                     contentSearchModalSelector + ' button.search'
      .waitForElementVisible     paneSelector + ' .search-result', 20000 # Assertion
      .waitForElementNotPresent  activeUntitledFileSelector, 20000 # Assertion
      .getText                   fileNameSelector, (result = {}) ->

        fileName  = result.value.split('/')?.reverse()[0]
        lowercase = fileName?.replace(/\./g, '').toLowerCase()

        return browser.end() unless lowercase

        tabHandleSelector = ".panel-1 div[title='#{fileName}']"
        editorSelector    = ".panel-1 .kdtabpaneview.active.#{lowercase} .ace_content"

        browser
          .waitForElementVisible     matchedWordSelector, 20000
          .click                     matchedWordSelector
          .waitForElementNotPresent  paneSelector + '.search-result .active', 20000 # Assertion
          .waitForElementVisible     tabHandleSelector, 20000
          .waitForElementVisible     editorSelector, 20000
          .assert.containsText       editorSelector, 'hello'
          .end()


  jumpToFile: (browser) ->

    helpers.beginTest(browser)
    helpers.waitForVMRunning(browser)

    searchModalSelector  = '.file-finder'
    findInFilesSelector  = '.kdlistview-contextmenu li.find-file-by-name'
    paneSelector         = '.pane-wrapper .kdsplitview-panel .application-tab-handle-holder .pythonpy'

    ideHelpers.openNewFile(browser)
    ideHelpers.openContextMenu(browser)

    browser
      .waitForElementVisible   findInFilesSelector, 20000
      .click                   findInFilesSelector
      .waitForElementVisible   searchModalSelector, 20000
      .setValue                searchModalSelector + ' input.text', 'python'
      .waitForElementVisible   searchModalSelector + ' .file-item:first-child', 20000
      .click                   searchModalSelector + ' .file-item:first-child'
      .waitForElementVisible   '.ws-tabview .kdtabview .pythonpy.active', 20000 # Assertion
      .waitForElementVisible   paneSelector, 20000 # Assertion
      .end()


  saveUntitledFile: (browser) ->

    helpers.beginTest(browser)
    helpers.waitForVMRunning(browser)

    ideHelpers.createAndSaveNewFile(browser)

    browser.end()


  # toggleInvisibleFiles: (browser) ->

  #   user = helpers.beginTest(browser)
  #   helpers.waitForVMRunning(browser)

  #   pathSelector = "span[title='/home/#{user.username}/.bashrc']"

  #   browser.element 'css selector', pathSelector, (result) =>
  #     if result.status is 0
  #      ideHelpers.toggleInvisibleFiles(browser, user)
  #     else
  #       helpers.clickVMHeaderButton(browser)
  #       browser
  #         .click '.context-list-wrapper .toggle-invisible-files'
  #         .waitForElementVisible    pathSelector, 20000 # Assertion

  #         ideHelpers.toggleInvisibleFiles(browser, user)

  #     browser.end()



  # openAnExistingFileAndSave: (browser) ->

  #   activeEditorSelector = '.pane-wrapper .kdsplitview-panel.panel-1 .kdtabpaneview.active'


  #   user = helpers.beginTest(browser)
  #   helpers.waitForVMRunning(browser)

  #   text     = helpers.getFakeText()
  #   fileName = ideHelpers.createAndSaveNewFile(browser, text)

  #   ideHelpers.closeFile(browser, fileName)
  #   ideHelpers.openAnExistingFile(browser, user, fileName, text)

  #   text = helpers.getFakeText()

  #   ideHelpers.setTextToEditor(browser, text)

  #   browser
  #     .assert.containsText    activeEditorSelector, text # Assertion

  #   ideHelpers.saveFile(browser)
  #   ideHelpers.closeFile(browser, fileName)
  #   ideHelpers.openAnExistingFile(browser, user, fileName, text)

  #   browser
  #     .assert.containsText    activeEditorSelector, text # Assertion

  #   browser.end()
