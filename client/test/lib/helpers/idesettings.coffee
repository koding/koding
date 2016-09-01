settingsSelector = '.kdtabhandle.settings'
settingsHeader = '.settings-pane .settings-header'

module.exports =
  enableAutosave: (browser) ->
  	browser
  		.waitForElementVisible  settingsSelector, 20000
  		.click settingsSelector
  		.waitForElementVisible settingsHeader, 20000
  		.waitForElementVisible '.settings-pane li:nth-of-type(1)', 20000
  		.click '.settings-pane li:nth-of-type(1)'

