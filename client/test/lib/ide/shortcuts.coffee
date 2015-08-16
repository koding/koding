helpers         = require "../helpers/helpers.js"
assert          = require "assert"
layoutHelpers   = require "../helpers/layoutHelpers.js"
shortcutHelpers = require "../helpers/shortcutHelpers.js"
ideHelpers      = require "../helpers/ideHelpers.js"

module.exports =

  testBasicShortcuts: (browser) ->

    helpers.beginTest(browser)
    helpers.waitForVMRunning(browser)

    # Ctrl+ALT+O - Search file by name
    shortcutHelpers.ctrlAltKey(browser, "o")
    browser.waitForElementVisible(".file-finder", 20000)
    shortcutHelpers.escape(browser) # Assertion

    # Ctrl+ALT+F - Search all files
    shortcutHelpers.ctrlAltKey(browser, "f")
    browser.waitForElementVisible(".formline.whereinput", 20000)
    shortcutHelpers.escape(browser) # Assertion

    # Ctrl+ALT+K - Hide/show sidebar
    shortcutHelpers.ctrlAltKey(browser, "k")
    browser.waitForElementVisible(".kdsplitview-panel.panel-0.floating", 20000) # Assertion

    browser.end()

  testWorkspaceManipulationShortcuts: (browser) ->

    helpers.beginTest(browser)
    helpers.waitForVMRunning(browser)

    # Ctrl+ALT+V - Split vertically
    verticalSelector = ".panel-1 .kdsplitview-vertical"
    layoutHelpers.getNumberOfPanels browser, verticalSelector, (length) ->
      shortcutHelpers.ctrlAltKey(browser, "v")
      browser.waitForElementVisible(".panel-1", 20000)
      layoutHelpers.assertSplit(browser, verticalSelector, length) # Assertion

    # Ctrl+ALT+H - Split horizontally
    horizontalSelector = ".panel-1 .kdsplitview-horizontal"
    layoutHelpers.getNumberOfPanels browser, verticalSelector, (length) ->
      shortcutHelpers.ctrlAltKey(browser, "h")
      browser.waitForElementVisible(".panel-1",20000)
      layoutHelpers.assertSplit(browser, horizontalSelector, length) # Assertion

    # Ctrl+ALT+M - Merge panels
    allSplitSelector = ".kdtabpaneview .kdsplitview-panel.panel-1"
    doMerge = (layoutHelpers, prevLength) ->
      layoutHelpers.getNumberOfPanels browser, allSplitSelector, (result)->
        if result isnt 1
          assert(prevLength != result, "Shortcut Ctrl+ALT+M failed") # Assertion
          shortcutHelpers.ctrlAltKey(browser,"m")
          doMerge(layoutHelpers, result)
    doMerge(layoutHelpers)

    browser.pause 2500

    browser.end()

  testTabShortcuts: (browser) ->

    helpers.beginTest(browser)
    helpers.waitForVMRunning(browser)

    ideHelpers.closeAllTabs(browser)

    # Ctrl+ALT+T - New terminal tab
    shortcutHelpers.ctrlAltKey(browser,"t")
    browser.waitForElementVisible(".kdtabhandle.terminal", 20000) # Assertion

    # Ctrl+ALT+N - New file tab
    shortcutHelpers.ctrlAltKey(browser,"n")
    browser.waitForElementVisible(".kdtabhandle.untitled-1txt", 20000) # Assertion

    # Create tabs for tab switching shortcuts
    shortcutHelpers.ctrlAltKey(browser,"t")
    shortcutHelpers.ctrlAltKey(browser,"n") for i in [ 0 .. 4 ]

    ideHelpers.getTabHandleElements browser, (result)->
      i = 1
      doCheck = ->
        shortcutHelpers.cmdKey(browser,"#{i}")
        browser.element 'css selector',".panel-1 .kdtabhandle.active", (elem)->
          assert(elem.value.ELEMENT is result[i-1].ELEMENT, "Shortcut CMD+#{i} failed")
          i++
          if i <= 6 then doCheck() else browser.end()
      doCheck()
