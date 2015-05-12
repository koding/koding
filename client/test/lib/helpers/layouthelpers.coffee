helpers = require './helpers.js'
assert  = require 'assert'

paneSelector      = '.pane-wrapper .panel-1 .application-tab-handle-holder'
plusSelector      = paneSelector + ' .visible-tab-handle.plus'
undoSplitSelector = paneSelector + ' .general-handles .close-handle'
newPaneSelector   = '.kdsplitcomboview .kdsplitview-panel.panel-1 .application-tab-handle-holder'

module.exports =


  openMenuAndClick: (browser, selector) ->

    browser
      .pause                   5000
      .waitForElementVisible   '.panel-1 .panel-0 .application-tab-handle-holder', 20000
      .moveToElement           plusSelector, 60, 17
      .click                   plusSelector
      .waitForElementVisible   '.context-list-wrapper', 20000
      .click                   '.context-list-wrapper ' + selector


  undoSplit: (browser) ->

    browser
      .waitForElementVisible '.panel-1', 20000
      .elements 'css selector', '.panel-1', (result) =>
        assert.equal result.value.length, 2

        browser
          .waitForElementVisible    paneSelector, 20000
          .click                    undoSplitSelector
          .waitForElementNotPresent '.pane-wrapper .kdsplitview-panel.panel-1 .application-tab-handle-holder', 20000

        browser.elements 'css selector', newPaneSelector, (result) =>
          assert.equal result.value.length, 1


  split: (browser, selector) ->

    browser
      .waitForElementVisible '.panel-1', 20000
      .elements 'css selector', '.panel-1', (result) =>
        assert.equal result.value.length, 2

        @openMenuAndClick(browser, selector)

        browser.elements 'css selector', '.panel-1', (result) =>
          assert.equal result.value.length, 3
