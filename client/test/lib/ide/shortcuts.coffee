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
    shortcutHelpers.escape(browser)

    # Ctrl+ALT+F - Search all files
    shortcutHelpers.ctrlAltKey(browser, "f")
    browser.waitForElementVisible(".formline.whereinput", 20000)
    shortcutHelpers.escape(browser)

    # Ctrl+ALT+V - Split vertically
    verticalSelector = ".panel-1 .kdsplitview-vertical"
    layoutHelpers.getNumberOfPanels browser, verticalSelector, (length) ->
      shortcutHelpers.ctrlAltKey(browser, "v")
      browser.waitForElementVisible(".panel-1", 20000)
      layoutHelpers.assertSplit(browser, verticalSelector, length)

    # Ctrl+ALT+H - Split horizontally
    horizontalSelector = ".panel-1 .kdsplitview-horizontal"
    layoutHelpers.getNumberOfPanels browser, verticalSelector, (length) ->
      shortcutHelpers.ctrlAltKey(browser, "h")
      browser.waitForElementVisible(".panel-1",20000)
      layoutHelpers.assertSplit(browser, horizontalSelector, length)
      browser.end()

