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

    # Ctrl+ALT+F - Search all files
    shortcutHelpers.ctrlAltKey(browser, "o")
    browser.waitForElementVisible(".formline.whereinput")

    # Ctrl+ALT+V - Split vertically
    shortcutHelpers.ctrlAltKey(browser, "v")
    browser.waitForElementVisible(".panel-1", 20000)
    layoutHelpers.assertSplit(browser, ".panel-1 .kdsplitview-vertical")

    # Ctrl+ALT+H - Split horizontally
    shortcutHelpers.ctrlAltKey(browser, "h")
    browser.waitForElementVisible(".panel-1",20000)
    layoutHelpers.assertSplit(browser, ".panel-1 .kdsplitview-horizontal"
