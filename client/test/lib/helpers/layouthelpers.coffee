helpers = require './helpers.js'
assert  = require 'assert'

paneSelector      = '.panel-1 .application-tab-handle-holder'
plusSelector      = paneSelector + ' .visible-tab-handle.plus'
undoSplitSelector = paneSelector + ' .general-handles .close-handle'
newPaneSelector   = '.kdsplitcomboview .kdsplitview-panel.panel-1 .application-tab-handle-holder'

module.exports =


  openMenuAndClick: (browser, selector) ->

    browser
      .waitForElementVisible   paneSelector, 20000
      .moveToElement           plusSelector, 60, 17
      .click                   plusSelector
      .waitForElementVisible   '.context-list-wrapper', 20000
      .click                   '.context-list-wrapper ' + selector


  waitForSnapshotRestore: (browser) ->

    browser.pause 7500 # find a better way


  undoSplit: (browser, shouldAssert = yes) ->

    @waitForSnapshotRestore browser

    browser
      .waitForElementVisible '.panel-1', 20000
      .elements 'css selector', '.panel-1', (result) =>
        oldLength = result.value.length

        browser
          .waitForElementVisible    paneSelector, 20000
          .click                    undoSplitSelector

          if shouldAssert
            browser.elements 'css selector', newPaneSelector, (result) =>
              assert.equal result.value.length, oldLength - 1


  split: (browser, direction) ->

    if direction is 'vertical'
      splitButtonSelector = 'li.split-vertically'
      splitViewSelector   = '.panel-1 .kdsplitview-vertical'
    else
      splitButtonSelector = 'li.split-horizontally'
      splitViewSelector   = '.panel-1 .kdsplitview-horizontal'

    @waitForSnapshotRestore browser
    browser
      .waitForElementVisible '.panel-1', 20000
      .elements 'css selector', splitViewSelector, (result) =>
        length = result.value.length

        if length >= 1
          console.log(' ✔ Views already splitted. Ending test...')
          browser.end()
        else
          @openMenuAndClick(browser, splitButtonSelector)
          browser.pause 2000

          browser.elements 'css selector', splitViewSelector, (result) =>
            assert.equal result.value.length, length + 1
            browser.pause 2000 # wait for snapshot write
