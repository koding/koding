helpers = require '../helpers/helpers.js'
utils = require '../utils/utils.js'
async = require 'async'
path = require 'path'
settingsSelector = '.kdtabhandle.settings'
settingsHeader = '.settings-pane .settings-header'

module.exports =
  enableAutosave: (browser, callback) ->
  	browser
  		.waitForElementVisible  settingsSelector, 20000
  		.click settingsSelector
  		.waitForElementVisible settingsHeader, 20000
  		.waitForElementVisible '.settings-pane li:nth-of-type(1)', 20000
  		.click '.settings-pane li:nth-of-type(1) .settings-on-off'

  	browser.pause 1000, -> 
  		callback()


  toggleLineNumbers: (browser, user, callback) ->
  	browser
  		.waitForElementVisible  settingsSelector, 20000
  		.click settingsSelector
  		.waitForElementVisible settingsHeader, 20000
  		.waitForElementVisible '.settings-pane li:nth-of-type(3)', 20000
  		.click '.settings-pane li:nth-of-type(3) .settings-on-off'
  	helpers.createFile browser, user, null, null, null, (res) ->
  		callback()



