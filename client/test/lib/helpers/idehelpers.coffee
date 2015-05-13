helpers           = require './helpers.js'
panelSelector     = '.pane-wrapper .kdsplitview-panel.panel-1'
tabHandleSelector = "#{panelSelector} .application-tab-handle-holder"

activeEditorSelector = '.pane-wrapper .kdsplitview-panel.panel-1 .kdtabpaneview.active'
filesTabSelector    = '.ide-files-tab .file-container'

module.exports =

  openNewFile: (browser) ->

    activeEditorSelector = '.pane-wrapper .kdsplitview-panel.panel-1 .kdtabpaneview.active .ace_content'
    plusSelector         = tabHandleSelector + ' .visible-tab-handle.plus'

    browser
      .waitForElementVisible  plusSelector, 20000
      .click                  plusSelector
      .waitForElementVisible  '.kdlistview-contextmenu li.new-file', 20000
      .click                  '.kdlistview-contextmenu li.new-file'
      .waitForElementVisible  activeEditorSelector, 20000 # Assertion


  openContextMenu: (browser) ->

    fileSelector    = "#{tabHandleSelector} .active"
    optionsSelector = "#{fileSelector} span.options"

    browser
      .waitForElementVisible  fileSelector, 20000
      .moveToElement          fileSelector, 60, 17
      .moveToElement          optionsSelector, 8, 8
      .waitForElementVisible  optionsSelector, 20000
      .click                  optionsSelector
      .waitForElementVisible  '.kdlistview-contextmenu', 20000 # Assertion


  createAndSaveNewFile: (browser, text) ->

    saveSelector        = '.kdlistview-contextmenu li.save'
    saveAsModalSelector = '.save-as-dialog'
    saveAsInputSelector = "#{saveAsModalSelector} input[type=text]"
    newName             = helpers.getFakeText().split(' ')[0] + '.txt'

    saveButtonSelector  = "#{saveAsModalSelector} .kddialog-buttons span.button-title"

    @openNewFile(browser)

    if text
      @setTextToEditor browser, text

    @openContextMenu(browser)

    browser
      .waitForElementVisible  saveSelector, 20000
      .click                  saveSelector
      .waitForElementVisible  saveAsModalSelector, 20000
      .waitForElementVisible  saveAsInputSelector, 20000
      .clearValue             saveAsInputSelector
      .setValue               saveAsInputSelector, newName
      .click                  saveButtonSelector
      .waitForElementVisible  "#{tabHandleSelector} div[title='#{newName}']", 20000 # Assertion
      .waitForElementVisible  filesTabSelector, 20000
      .assert.containsText    filesTabSelector, newName # Assertion

    if text
      browser.assert.containsText panelSelector, text

    return newName


  setTextToEditor: (browser, text) ->

    browser.execute "_kd.singletons.appManager.frontApp.activeTabView.activePane.view.setContent('#{text}')"



  saveFile: (browser) ->

    saveSelector      = '.kdlistview-contextmenu li.save'
    saveIconSelector  = "#{tabHandleSelector} .modified"

    @openContextMenu(browser)

    browser
      .waitForElementVisible    saveSelector, 20000
      .click                    saveSelector
      .waitForElementNotPresent saveIconSelector, 20000 # Assertion


  closeFile: (browser, fileName) ->

    closeFileSelector = "#{tabHandleSelector} span.close-tab"

    browser
      .moveToElement             tabHandleSelector, 60, 15
      .waitForElementVisible     closeFileSelector, 20000
      .click                     closeFileSelector
      .waitForElementNotPresent  "#{tabHandleSelector} div[title='#{fileName}']", 20000 # Assertion


  openAnExistingFile: (browser, user, fileName, text) ->

    fileSelector        = "#{filesTabSelector} span[title='/home/#{user.username}/#{fileName}']"
    fileChevronSelector = "#{fileSelector} + .chevron"

    browser
      .waitForElementVisible  filesTabSelector, 20000
      .pause                  3000
      .waitForElementVisible  fileSelector, 20000
      .moveToElement          fileSelector, 70, 12
      .waitForElementVisible  fileChevronSelector, 20000
      .click                  fileChevronSelector
      .waitForElementVisible  'li.open-file', 20000
      .click                  'li.open-file'
      .waitForElementVisible  "#{tabHandleSelector} div[title='#{fileName}']", 20000 # Assertion
      .assert.containsText    activeEditorSelector, text # Assertion


  openFile: (browser, user, fileName) ->

    filePath            = "/home/#{user.username}/Web/#{fileName}"
    fileSelector        = "span[title='#{filePath}']"
    chevronSelector     = "#{fileSelector} + span.chevron"
    contextMenuSelector = '.kdlistview-contextmenu'
    openFileSelector    = "#{contextMenuSelector} li.open-file"
    fileTabSelector     = "div[title='#{fileName}']"

    browser
      .waitForElementVisible  fileSelector, 20000
      .moveToElement          fileSelector, 120, 12
      .waitForElementVisible  chevronSelector, 20000
      .click                  chevronSelector
      .waitForElementVisible  contextMenuSelector, 20000
      .click                  openFileSelector
      .waitForElementVisible  fileTabSelector, 20000
