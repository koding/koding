helpers       = require '../helpers/helpers.js'
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
    newPaneSelector = '.kdsplitcomboview .kdsplitview-panel.panel-1 .application-tab-handle-holder'

    fn = ->
      browser.elements 'css selector', newPaneSelector, (result) ->
        if result.value.length is 1
          browser
            .waitForElementPresent '.panel-1 .general-handles .close-handle.hidden', 20000 # Assertion
            .end()
        else
          layoutHelpers.undoSplit(browser, no)
          fn()

    layoutHelpers.waitForSnapshotRestore(browser)
    fn()


  openDrawingBoard: (browser) ->

    handleSelector     = '.kdtabhandle.drawing'
    activePaneSelector = '.kdtabpaneview.drawing.active .drawing-pane'

    helpers.beginTest(browser)
    helpers.waitForVMRunning(browser)

    fn = ->
      browser.elements 'css selector', handleSelector, (result) ->
        if result.value.length > 0
          console.log(' ✔ A drawing board is already opened. Ending test...')
          browser.end()
        else
          layoutHelpers.openMenuAndClick(browser, '.new-drawing-board')

          browser
            .pause 4000
            .waitForElementVisible handleSelector + '.active', 20000
            .waitForElementVisible activePaneSelector, 20000 # Assertion
            .waitForElementVisible activePaneSelector + ' .drawing-board-toolbar', 20000 # Assertion
            .end()

    layoutHelpers.waitForSnapshotRestore(browser)
    fn()


  collapseExpandFileTree: (browser) ->

    tabSelector             = '.kdtabhandle-tabs.clearfix'
    fileTabSelector         = "#{tabSelector} .files"
    settingsTabSelector     = "#{tabSelector} .settings"
    collapseButton          = '.application-tab-handle-holder .general-handles'
    collapsedWindowSelector = '.kdview.kdscrollview.kdsplitview-panel.panel-0.floating'
    settingsHeaderSelector  = '.kdsplitview-panel.panel-0 .settings-header'

    user = helpers.beginTest(browser)
    helpers.waitForVMRunning(browser)

    browser
      .waitForElementVisible        fileTabSelector, 20000
      .moveToElement                fileTabSelector, 5, 5
      .waitForElementVisible        collapseButton, 20000
      .click                        collapseButton
      .waitForElementVisible        collapsedWindowSelector, 20000
      .click                        fileTabSelector
      .waitForElementNotPresent     collapsedWindowSelector, 20000
      .click                        collapseButton
      .waitForElementVisible        collapsedWindowSelector, 20000
      .click                        settingsTabSelector
      .waitForElementNotPresent     collapsedWindowSelector, 20000
      .assert.containsText          settingsHeaderSelector, 'Editor Settings'
      .end()


