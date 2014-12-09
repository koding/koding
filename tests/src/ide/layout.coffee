utils   = require '../utils/utils.js'
helpers = require '../helpers/helpers.js'
faker   = require 'faker'
assert  = require 'assert'


module.exports =


  splitPanesVertically: (browser) ->

    helpers.beginTest(browser)
    helpers.waitForVMRunning(browser)

    browser
      .waitForElementVisible '.panel-1', 20000
      .elements 'css selector', '.panel-1', (result) =>
        assert.equal result.value.length, 2

        browser
          .waitForElementVisible   '.application-tab-handle-holder', 20000
          .click                   '.application-tab-handle-holder .plus'
          .waitForElementVisible   '.context-list-wrapper', 20000
          .click                   '.context-list-wrapper li.split-vertically'
          .pause                   2000

        .elements 'css selector', '.panel-1', (result) =>
          assert.equal result.value.length, 3
        .end()


  splitPanesHorizontally: (browser) ->

    helpers.beginTest(browser)
    helpers.waitForVMRunning(browser)

    browser
      .waitForElementVisible '.panel-1', 20000
      .elements 'css selector', '.panel-1', (result) =>
        assert.equal result.value.length, 2

        browser
          .waitForElementVisible   '.application-tab-handle-holder', 20000
          .click                   '.application-tab-handle-holder .plus'
          .waitForElementVisible   '.context-list-wrapper', 20000
          .click                   '.context-list-wrapper li.split-horizontally'
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
