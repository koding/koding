helpers = require '../helpers/helpers.js'
teamsHelpers = require '../helpers/teamshelpers.js'
utilitiesLink = "#{helpers.getUrl(yes)}/Home/koding-utilities"


module.exports =

  kdCLI: (browser) ->

    sectionSelector = '.HomeAppView--section.kd-cli'
    codeBlockSelector = "#{sectionSelector} .HomeAppView--code.block"
    codeBlockText = "#{codeBlockSelector} span"

    user = teamsHelpers.loginTeam browser

    browser
      .url utilitiesLink
      .waitForElementVisible sectionSelector, 20000
      .assert.containsText codeBlockText, 'https://kodi.ng/d/kd'
      .pause 5000
      .click codeBlockSelector
      .waitForElementVisible '.kdnotification', 20000
      .assert.containsText '.kdnotification', 'Copied to clipboard!'
