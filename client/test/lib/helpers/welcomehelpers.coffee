helpers = require '../helpers/helpers.js'
teamsHelpers = require '../helpers/teamshelpers.js'
myTeamLink = "#{helpers.getUrl(yes)}/Home/my-team"

module.exports =

  seeStackView: (browser) ->
    stackLink = '.WelcomeStacksView ul.bullets li:nth-of-type(1)'
    browser
      .pause 3000
      .waitForElementVisible '.WelcomeStacksView', 20000
      .click stackLink
      .waitForElementVisible '.StackEditor-OnboardingModal', 20000

  seeTeamView: (browser) ->
    teamLink = '.WelcomeStacksView ul.bullets li:nth-of-type(2)'
    browser
      .pause 3000
      .waitForElementVisible '.WelcomeStacksView', 20000
      .click teamLink
      .waitForElementVisible '.HomeAppView--section.send-invites', 20000      
     

  seeKDInstall: (browser) ->
    browser
      .waitForElementVisible '.WelcomeStacksView', 2000   
      .click '.WelcomeStacksView ul.bullets li:nth-of-type(3)'
      .waitForElementVisible '.HomeAppView--section.kd-cli', 20000
      .pause 3000
  

  seePendingStackView: (browser) ->
    pendingStack = '.WelcomeStacksView ul.bullets li:nth-of-type(1)'
    browser
      .waitForElementVisible '.WelcomeStacksView', 20000
      .assert.containsText   pendingStack, 'Your Team Stack is Pending'
        
  
  seePersonalStackView: (browser, targetUser) ->
    stackLink = '.WelcomeStacksView ul.bullets li:nth-of-type(2)'
    browser
      .pause 3000
      .waitForElementVisible '.WelcomeStacksView', 20000
      .click stackLink
      .waitForElementVisible '.StackEditor-OnboardingModal', 20000


  seePricingDetails: (browser)->
    browser
      .pause 2000
      .click '.HomeAppView--button:nth-of-type(2)', (result) ->
        if result.state is 'success'
          helpers.switchBrowser browser, 'http://www.koding.com/pricing'
          

  seeMembers: (browser)->
    browser
      .pause 2000
      .click '.HomeAppView--button:nth-of-type(1)'
      .waitForElementVisible '.HomeAppView--section.team-settings', 20000
      .assert.containsText '.HomeAppView--sectionHeader', 'Team Settings'
    

  seePaymentHistory: (browser) ->
    browser
      .scrollToElement '.HomeAppView--billing-form'
      .click '.HomeAppView--button.custom-link-view.primary:nth-of-type(2)'
      .pause 3000
      .assert.containsText '.HomeAppView--sectionHeader', 'Payment History'
      .waitForElementVisible 'div.HomeAppView--section.HomeTeamInvoicesList', 20000


  removeCard: (browser) ->
    browser
      .scrollToElement '.HomeAppView--billing-form'
      .click '.HomeAppView--button.custom-link-view.primary:nth-of-type(1)'
      .pause 3000
