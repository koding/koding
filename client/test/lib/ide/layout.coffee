helpers       = require '../helpers/helpers.js'
assert        = require 'assert'
layoutHelpers = require '../helpers/layouthelpers.js'


module.exports =


  splitPanesVertically: (browser) ->

    helpers.beginTest(browser)
    helpers.waitForVMRunning(browser)

    layoutHelpers.split(browser, 'vertical')
    browser.end()


  splitPanesHorizontally: (browser) ->

    helpers.beginTest(browser)
    helpers.waitForVMRunning(browser)

    layoutHelpers.split(browser, 'horizontal')
    browser.end()


  undoSplitPanes: (browser) ->

    helpers.beginTest(browser)
    helpers.waitForVMRunning(browser)

    layoutHelpers.undoSplit(browser)
    browser.end()


  undoSplitPanesNotShowOnScreen: (browser) ->

    helpers.beginTest(browser)
    helpers.waitForVMRunning(browser)

    newPaneSelector   = '.kdsplitcomboview .kdsplitview-panel.panel-1 .application-tab-handle-holder'

    layoutHelpers.undoSplit(browser)

    browser
      .waitForElementVisible   newPaneSelector, 20000
      .waitForElementPresent   newPaneSelector + ' .general-handles .close-handle.hidden', 20000 # Assertion
      .end()


  openDrawingBoard: (browser) ->

    helpers.beginTest(browser)
    helpers.waitForVMRunning(browser)

    layoutHelpers.openMenuAndClick(browser, '.new-drawing-board')

    browser
      .pause 4000
      .waitForElementVisible   '.pane-wrapper .kdsplitview-panel.panel-1 .drawing-pane .drawing-board-toolbar', 20000 # Assertion
      .end()
