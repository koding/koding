helpers = require '../helpers/helpers.js'
assert  = require 'assert'

paneSelector = '.pane-wrapper .kdsplitview-panel.panel-1 .application-tab-handle-holder'

split = (browser, selector) ->

  helpers.beginTest(browser)
  helpers.waitForVMRunning(browser)

  browser
    .waitForElementVisible '.panel-1', 20000
    .elements 'css selector', '.panel-1', (result) =>
      assert.equal result.value.length, 2

      browser
        .waitForElementVisible   '.panel-1 .panel-0 .application-tab-handle-holder', 20000
        .moveToElement           '.panel-1 .panel-0 .application-tab-handle-holder .plus', 60, 17
        .pause  300
        .click                   '.panel-1 .panel-0 .application-tab-handle-holder .plus'
        .waitForElementVisible   '.context-list-wrapper', 20000
        .click                   '.context-list-wrapper ' + selector
        .pause                   2000

      .elements 'css selector', '.panel-1', (result) =>
        assert.equal result.value.length, 3
      .end()


module.exports =


  splitPanesVertically: (browser) ->

    split(browser, 'li.split-vertically')


  splitPanesHorizontally: (browser, selector) ->

    helpers.beginTest(browser)
    helpers.waitForVMRunning(browser)

    browser
      .waitForElementVisible '.panel-1', 20000
      .elements 'css selector', '.panel-1', (result) =>
        assert.equal result.value.length, 2

        browser
          .waitForElementVisible   paneSelector + ' .plus', 20000
          .pause   2000
          .click                   paneSelector + ' .plus'
          .waitForElementVisible   '.context-list-wrapper', 20000
          .pause   2000
          .click                   '.context-list-wrapper ' + ' .split-horizontally'
          .pause                   2000

        .elements 'css selector', '.panel-1', (result) =>
          assert.equal result.value.length, 3
        .end()


  splitPanesUndo: (browser) ->

    helpers.beginTest(browser)
    helpers.waitForVMRunning(browser)

    helpers.splitPanesUndo(browser)
    browser.end()


  undoSplitPanesNotShowOnList: (browser) ->

    helpers.beginTest(browser)
    helpers.waitForVMRunning(browser)

    helpers.splitPanesUndo(browser)

    browser
      .waitForElementVisible     '.application-tab-handle-holder', 20000
      .click                     '.application-tab-handle-holder .plus'
      .waitForElementNotPresent  '.context-list-wrapper li.undo-split', 20000 # Assertion
      .end()


  openDrawingBoard: (browser) ->

    helpers.beginTest(browser)
    helpers.waitForVMRunning(browser)

    browser
      .waitForElementVisible   paneSelector + ' .plus', 20000
      .pause   2000
      .click                   paneSelector + ' .plus'
      .waitForElementVisible   '.context-list-wrapper', 20000
      .pause   2000
      .click                   '.context-list-wrapper ' + ' .new-drawing-board'
      .pause                   2000
      .waitForElementVisible   '.drawing-pane .drawing-board-toolbar', 20000 # Assertion
      .end()
