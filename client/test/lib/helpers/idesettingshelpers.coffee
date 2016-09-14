helpers = require '../helpers/helpers.js'
utils = require '../utils/utils.js'
ideHelpers = require '../helpers/idehelpers.js'
async = require 'async'
path = require 'path'
settingsSelector = '.kdtabhandle.settings'
settingsHeader = '.settings-pane .settings-header'
lineNumberToggleSelector = '.settings-pane li:nth-of-type(3) .settings-on-off'
fileTabSelector = '.ide-files-tab .kdtabhandle.files'
activeEditorSelector = '.pane-wrapper .kdsplitview-panel.panel-1 .kdtabpaneview.active .ace_content'
lineNumber = '.ace_folding-enabled > .ace_gutter-cell'
user = utils.getUser()
fileName = 'text.txt'
fileSelector  = "span[title='/home/#{user.username}/.config/#{fileName}']"
text = 'test enable AutoSave'


module.exports =

  openSettingsMenu: (browser, callback = -> ) ->
    browser
      .waitForElementVisible  settingsSelector, 20000
      .click settingsSelector
      .waitForElementVisible settingsHeader, 20000
      .pause 10, -> callback()


  enableAutoSave: (browser, callback) ->
    @openSettingsMenu browser, =>
      @toogleOnOff browser, 1, yes, ->
        browser
          .waitForElementVisible fileTabSelector, 20000
          .click fileTabSelector, ->
            ideHelpers.openFile browser, user, fileName, ->
            browser.pause 1000
            ideHelpers.setTextToEditor browser, text
            browser.pause 3000
            ideHelpers.closeFile browser, fileName, user
            ideHelpers.openFile browser, user, fileName, ->
              browser.pause 2000
              browser.assert.containsText activeEditorSelector, text
              ideHelpers.closeFile browser, fileName, user
              browser.pause 1, callback()


  toggleLineNumbers: (browser, user, callback) ->
    @openSettingsMenu browser, =>
      @toogleOnOff browser, 3, no, =>
        browser.click fileTabSelector, =>
          browser.waitForElementVisible fileSelector, 40000
          ideHelpers.openFile browser, user, fileName, =>
            ideHelpers.setTextToEditor browser, text
            browser.pause 2000
            browser.waitForElementNotVisible lineNumber, 20000
            @openSettingsMenu browser, =>
              @toogleOnOff browser, 3, yes, ->
                browser.waitForElementVisible lineNumber, 40000
                ideHelpers.closeFile browser, fileName, user
                browser.pause 1, callback()


  showInvisibles: (browser, callback) ->
    @openSettingsMenu browser, =>
      @toogleOnOff browser, 8, yes, =>
        @openSettingsMenu browser, =>
          @toogleOnOff browser, 8, no, ->
            browser.pause 1, callback()


  toogleOnOff: (browser, index, isOn, callback) ->
    browser.waitForElementVisible toggleElementSelector(index), 20000

    if isOn
      browser.element 'css selector', toggleElementSelector(index) + '.off', (result) ->
        if result.status is 0
          browser.click toggleElementSelector(index)
          browser.waitForElementVisible toggleElementSelector(index) + '.on', 20000
    else
      browser.element 'css selector', toggleElementSelector(index) + '.on', (result) ->
        if result.status is 0
          browser.click toggleElementSelector(index)
          browser.waitForElementVisible toggleElementSelector(index) + '.off', 20000

    browser.pause 1, -> callback()


toggleElementSelector = (index) ->
  ".settings-pane li:nth-of-type(#{index}) .settings-on-off"
