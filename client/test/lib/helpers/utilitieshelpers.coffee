helpers                     = require '../helpers/helpers.js'
teamsHelpers                = require '../helpers/teamshelpers.js'
utils                       = require '../utils/utils.js'
http                        = require 'http'
utilitiesLink               = "#{helpers.getUrl(yes)}/Home/koding-utilities"
sectionSelector             = '.HomeAppView--section.kd-cli'
codeBlockSelector           = "#{sectionSelector} .HomeAppView--code.block"
codeBlockText               = "#{codeBlockSelector} span"

kodingAppSelector           = '.HomeAppView--section.koding-app'
kodingAppLink               = "a[href='https://koding-cdn.s3.amazonaws.com/koding-app/Koding-mac.zip']"
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
WelcomeView                 = '.WelcomeStacksView'

module.exports =

  checkKdCliCodeBlock: (browser, done) ->

    browser
      .url utilitiesLink
      .waitForElementVisible sectionSelector, 40000
      .assert.containsText codeBlockText, 'd/kd | bash -s'
      .pause 1000
      .click codeBlockSelector
      .waitForElementVisible '.kdnotification', 20000
      .assert.containsText '.kdnotification', 'Copied to clipboard!'
      .pause 1000, done


  downloadKodingApp: (browser, done) ->

    browser
      .scrollToElement kodingAppSelector
      .waitForElementVisible kodingAppSelector, 20000
      .waitForElementVisible kodingAppLink, 20000
      .pause 1000, done

  # downloadKodingApp: (browser, done) ->

    # options =
    #   host: "https://koding-cdn.s3.amazonaws.com"
    #   path: '/koding-app/Koding-mac.zip'
    #   port: '80'

    # req = http.request options,  (res) ->
    #   data = ''
    #   res.on 'data', (chunk) ->
    #     console.log(chunk)
    #     data += "#{chunk}"
    #   res.on 'end', () ->
    #     console.log(data)

    # req.on "error", (e) ->
    #     console.log(e)

  checkViewGuideButton: (browser, buttonSelector, browserSelector, done) ->

    browser
      .click buttonSelector, (result) ->
        if result.state is 'success'
          helpers.switchBrowser browser, browserSelector
          browser.pause 1000, done


  enableTryOnKodingButton: (browser, done) ->

    browser
      .scrollToElement kodingButtonsectionSelector
      .waitForElementVisible kodingButtonsectionSelector, 20000
      .pause 2000
      .elements 'css selector', domainSelector, (result) ->

        unless result.value.length
          browser
            .waitForElementVisible toggleButtonSelector, 10000
            .click toggleButtonSelector
            .waitForElementVisible tryOnKodingButtonSelector, 20000
      .pause 1000, done


  disableTryOnKodingButton: (browser, done) ->

    browser
      .url utilitiesLink
      .waitForElementVisible sectionSelector, 40000
      .scrollToElement kodingButtonsectionSelector
      .waitForElementVisible kodingButtonsectionSelector, 20000
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
      .clearValue inputSelector
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


  seeTryOnKodingButton: (browser, done) ->

    targetUser1 = utils.getUser no, 1
    teamsHelpers.loginToTeam browser, targetUser1 , no, '', ->
      browser
        .waitForElementVisible WelcomeView, 60000
        .url utilitiesLink
        .waitForElementVisible sectionSelector, 40000
        .scrollToElement kodingButtonsectionSelector
        .waitForElementVisible kodingButtonsectionSelector, 20000
        .waitForElementNotPresent toggleButtonSelector, 10000
        .pause 2000, done


  loginToTeamWithRegisteredAccount: (browser, done) ->

    user =  utils.getUser no, 2
    teamsHelpers.logoutTeam browser, (res) ->
      teamsHelpers.loginToTeam browser, user , no, '', ->
        browser.waitForElementVisible WelcomeView, 60000, done


  loginToTeamWithNonRegisteredAccount: (browser, done) ->

    user =  utils.getUser no, 3
    teamsHelpers.logoutTeam browser, (res) ->
      teamsHelpers.loginTeam browser, user , no, '', ->
        browser
          .waitForElementVisible WelcomeView, 60000
          .url utilitiesLink
        teamsHelpers.loginToTeam browser, user , no, '', ->
          browser.waitForElementVisible sectionSelector, 60000, done
