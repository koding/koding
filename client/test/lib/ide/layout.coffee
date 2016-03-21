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
    settingsHeaderSelector  = '.kdtabhandle-tabs .settings.kddraggable.active'

    user = helpers.beginTest(browser)
    helpers.waitForVMRunning(browser)

    browser
      .waitForElementVisible        fileTabSelector, 20000
      .pause                        3000 # wait for file tree to load
      .moveToElement                fileTabSelector, 5, 5
      .waitForElementVisible        collapseButton, 20000
      .click                        collapseButton
      .pause                        500
      .waitForElementVisible        collapsedWindowSelector, 20000
      .click                        fileTabSelector
      .pause                        500
      .waitForElementNotPresent     collapsedWindowSelector, 20000
      .click                        collapseButton
      .pause                        500
      .waitForElementVisible        collapsedWindowSelector, 20000
      .click                        settingsTabSelector
      .pause                        500
      .waitForElementNotPresent     collapsedWindowSelector, 20000
      .waitForElementVisible        settingsHeaderSelector, 20000
      .end()


  collapseExpandSidebar: (browser) ->

    sidebarSelector         = '.kdview.with-sidebar .logo-wrapper'
    collapseButton          = '.logo-wrapper .sidebar-close-handle'
    collapsedWindowSelector = '.kdview.with-sidebar#kdmaincontainer.collapsed'
    hiddenExpandSelector    = '.sidebar-close-handle.hidden .icon'

    user = helpers.beginTest(browser)
    helpers.waitForVMRunning(browser)

    browser
      .waitForElementVisible     sidebarSelector, 20000
      .moveToElement             sidebarSelector, 5, 5
      .waitForElementVisible     collapseButton, 20000
      .click                     collapseButton
      .pause                     500
      .waitForElementVisible     collapsedWindowSelector, 20000
      .moveToElement             sidebarSelector, 5, 5
      .pause                     2000 # wait for hidden button to be displayed
      .click                     hiddenExpandSelector
      .pause                     500
      .waitForElementNotPresent  collapsedWindowSelector, 20000
      .end()


  enterExitFullScreenFromIdeHeader: (browser) ->

    ideHeaderSelector           = '.pane-wrapper .kdsplitview-panel.panel-0 .application-tab-handle-holder'
    enterExitFullScreenSelector = '.kdsplitview-horizontal .panel-0 .idetabhandle-holder .general-handles .fullscreen-handle'
    collapsedSidebarSelector    = '.kdview.with-sidebar#kdmaincontainer.collapsed'

    helpers.beginTest(browser)
    helpers.waitForVMRunning(browser)

    browser
      .waitForElementVisible     ideHeaderSelector, 20000
      .moveToElement             ideHeaderSelector, 10, 10
      .waitForElementVisible     enterExitFullScreenSelector, 20000
      .click                     enterExitFullScreenSelector
      .pause                     500 #pause for screen animation to finish
      .waitForElementVisible     collapsedSidebarSelector, 20000
      .moveToElement             ideHeaderSelector, 10, 10
      .waitForElementVisible     enterExitFullScreenSelector, 20000
      .click                     enterExitFullScreenSelector
      .pause                     500
      .waitForElementNotPresent  collapsedSidebarSelector, 20000
      .end()

