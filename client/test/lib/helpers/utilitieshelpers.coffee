helpers                     = require '../helpers/helpers.js'
utils                       = require '../utils/utils.js'
utilitiesLink               = "#{helpers.getUrl(yes)}/Home/koding-utilities"
sectionSelector             = '.HomeAppView--section.kd-cli'
codeBlockSelector           = "#{sectionSelector} .HomeAppView--code.block"
codeBlockText               = "#{codeBlockSelector} span"

kodingButtonsectionSelector = '.HomeAppView--section.koding-button'
toggleButtonSelector        = "#{kodingButtonsectionSelector} .ReactToggle.TryOnKoding-onOffButton"
kodingBtncodeBlockSelector  = "#{kodingButtonsectionSelector} .HomeAppView--code.block"
textarea                    = "#{kodingBtncodeBlockSelector} textarea"
tryOnKodingButtonSelector   = '.custom-link-view.TryOnKodingButton.fr'
viewGuideButton             = "#{kodingButtonsectionSelector} .custom-link-view.HomeAppView--button"
domainSelector              = '.react-toggle.react-toggle--checked'

integrationSectionSelector  = '.HomeAppView--section.customer-feedback'
chatlioLink                 = "#{integrationSectionSelector} .warning a"
chatlioViewGuideButton      = "#{integrationSectionSelector} a[href='https://www.koding.com/docs/chatlio'].custom-link-view.HomeAppView--button"
inputSelector               = "#{integrationSectionSelector} input[type=text]"
saveButton                  = "#{integrationSectionSelector} .custom-link-view.HomeAppView--button.primary.fr"
saveButtonTurnedOffResponse = 'Chatlio integration successfully turned off!'
saveButtonSaveResponse      = 'Chatlio id successfully saved!'

module.exports =

  checkKdCliCodeBlock: (browser, done) ->
    browser
      .url utilitiesLink
      .waitForElementVisible sectionSelector, 20000
      .assert.containsText codeBlockText, 'd/kd | bash -s'
      .pause 1000
      .click codeBlockSelector
      .waitForElementVisible '.kdnotification', 20000
      .assert.containsText '.kdnotification', 'Copied to clipboard!'
      .pause 1000, done


  checkViewGuideButton: (browser, buttonSelector, browserSelector, done) ->
    browser
      .click buttonSelector, (result) ->
        if result.state is 'success'
          helpers.switchBrowser browser, browserSelector
          browser.pause 1000, done


  enableDisableTryOnKodingButton: (browser, done) ->
    browser
      .url utilitiesLink
      .scrollToElement kodingButtonsectionSelector
      .waitForElementVisible kodingButtonsectionSelector, 20000
      .pause 2000
      .elements 'css selector', domainSelector, (result) ->

        unless result.value.length
          browser
            .waitForElementVisible toggleButtonSelector, 10000
            .click toggleButtonSelector
            .waitForElementVisible tryOnKodingButtonSelector, 20000
            .click toggleButtonSelector
      .pause 1000, done


  checkCodeBlock: (browser, done) ->
    browser
      .waitForElementVisible kodingBtncodeBlockSelector, 20000
      .click kodingBtncodeBlockSelector
      .waitForElementVisible '.kdnotification', 20000
      .assert.containsText '.kdnotification', 'Copied to clipboard!'
      .pause 1000, done


  saveChatlio: (browser, done) ->
    browser
      .scrollToElement integrationSectionSelector
      .waitForElementVisible integrationSectionSelector, 10000
      .waitForElementVisible saveButton, 5000
      .click saveButton
      .click saveButton
      .waitForElementVisible '.kdnotification', 10000
      .assert.containsText '.kdnotification', saveButtonTurnedOffResponse
      .pause 5000
      .waitForElementVisible inputSelector, 5000
      .setValue inputSelector, 'Chatlio data-widget-id'
      .pause 2000
      .click saveButton
      .waitForElementVisible '.kdnotification', 10000
      .assert.containsText '.kdnotification', saveButtonSaveResponse
      .pause 5000, done


  checkChatlioLink: (browser, done) ->
    browser
      .click chatlioLink, (result) ->
        if result.state is 'success'
          helpers.switchBrowser browser, 'chatlio.com'
      .pause 1000, done
