helpers           = require './helpers.js'
tabHandleSelector = "#{panelSelector} .application-tab-handle-holder"

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

    fileSelector    = "#{tabHandleSelector} .untitledtxt.active"
    optionsSelector = "#{fileSelector} span.options"

    browser
      .waitForElementVisible  fileSelector, 20000
      .moveToElement          fileSelector, 60, 17
      .moveToElement          optionsSelector, 8, 8
      .waitForElementVisible  optionsSelector, 20000
      .click                  optionsSelector
      .waitForElementVisible  '.kdlistview-contextmenu', 20000 # Assertion


  createAndSaveNewFile: (browser) ->

    saveSelector        = '.kdlistview-contextmenu li.save'
    saveAsModalSelector = '.save-as-dialog'
    saveAsInputSelector = "#{saveAsModalSelector} input[type=text]"
    newName             = helpers.getFakeText().split(' ')[0] + '.txt'
    filesTabSelector    = '.ide-files-tab .file-container'
    saveButtonSelector  = "#{saveAsModalSelector} .kddialog-buttons span.button-title"

    @openNewFile(browser)
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

    return newName


  setTextToEditor: (browser, text) ->

    browser.execute "_kd.singletons.appManager.frontApp.activeTabView.activePane.view.setContent('#{text}')"
