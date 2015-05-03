helpers      = require './helpers.js'
paneSelector = '.pane-wrapper .kdsplitview-panel.panel-1 .application-tab-handle-holder'

module.exports =

  openNewFile: (browser) ->

    activeEditorSelector = '.pane-wrapper .kdsplitview-panel.panel-1 .kdtabpaneview.active .ace_content'
    plusSelector         = paneSelector + ' .visible-tab-handle.plus'

    browser
      .waitForElementVisible  plusSelector, 20000
      .click                  plusSelector
      .waitForElementVisible  '.kdlistview-contextmenu li.new-file', 20000
      .click                  '.kdlistview-contextmenu li.new-file'
      .waitForElementVisible  activeEditorSelector, 20000 # Assertion


  openContextMenu: (browser) ->

    fileSelector = ' .untitledtxt.active'

    browser
      .waitForElementVisible  paneSelector + fileSelector, 20000
      .moveToElement          paneSelector + fileSelector, 60, 17
      .moveToElement          paneSelector + fileSelector + ' span.options', 8, 8
      .waitForElementVisible  paneSelector + fileSelector + ' span.options', 20000
      .click                  paneSelector + fileSelector + ' span.options'
      .waitForElementVisible  '.kdlistview-contextmenu', 20000 # Assertion

