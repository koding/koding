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
      .click '.HomeAppView--button.primary', (result) ->
        if result.state is 'success'
          helpers.switchBrowser browser, 'connect-your-machine'
      .end()


  kodingButton: (browser) ->

    sectionSelector = '.HomeAppView--section.koding-button'
    toggleButtonSelector = "#{sectionSelector} .ReactToggle.TryOnKoding-onOffButton"
    codeBlockSelector = "#{sectionSelector} .HomeAppView--code.block"
    textarea = "#{codeBlockSelector} textarea"
    tryOnKodingButtonSelector = '.custom-link-view.TryOnKodingButton.fr'
    viewGuideButton = "#{sectionSelector} .custom-link-view.HomeAppView--button"
    domainSelector = '.react-toggle.react-toggle--checked'

    user = teamsHelpers.loginTeam browser

    browser
      .url utilitiesLink
      .waitForElementVisible sectionSelector, 20000
      .pause 5000
      .elements 'css selector', domainSelector, (result) ->

        unless result.value.length
          browser
            .waitForElementVisible toggleButtonSelector, 10000
            .click toggleButtonSelector

      .pause 5000
      .waitForElementVisible codeBlockSelector, 20000
      .assert.valueContains textarea, user.teamSlug
      .click codeBlockSelector
      .waitForElementVisible '.kdnotification', 20000
      .assert.containsText '.kdnotification', 'Copied to clipboard!'
      .waitForElementVisible tryOnKodingButtonSelector, 20000
