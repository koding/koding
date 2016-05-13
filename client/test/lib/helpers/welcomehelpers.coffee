helpers = require '../helpers/helpers.js'
teamsHelpers = require '../helpers/teamshelpers.js'
myTeamLink = "#{helpers.getUrl(yes)}/Home/my-team"

module.exports =

  seeStackView: (browser) ->
    stackLink = ".WelcomeStacksView ul.bullets li:nth-of-type(1)"
    browser
      .pause 3000
      .waitForElementVisible '.WelcomeStacksView', 20000
      .click stackLink
      .waitForElementVisible '.StackEditor-OnboardingModal',20000        


  seeTeamView: (browser) ->
    teamLink = ".WelcomeStacksView ul.bullets li:nth-of-type(2)"
    browser
      .pause 3000
      .waitForElementVisible '.WelcomeStacksView', 20000
      .click teamLink
      .waitForElementVisible '.HomeAppView--section.send-invites',20000        
     

  seeKDInstall: (browser) ->
    browser
      .waitForElementVisible '.WelcomeStacksView', 2000        
      .click ".WelcomeStacksView ul.bullets li:nth-of-type(3)"
      .waitForElementVisible '.HomeAppView--section.kd-cli',20000
      .pause 3000
  

  seePendingStackView: (browser) ->
    pendingStack = ".WelcomeStacksView ul.bullets li:nth-of-type(1)"
    browser
      .waitForElementVisible '.WelcomeStacksView', 20000
      .assert.containsText   pendingStack, 'Your Team Stack is Pending'
        
  
  seePersonalStackView: (browser, targetUser) ->
    stackLink = ".WelcomeStacksView ul.bullets li:nth-of-type(2)"
    browser
      .pause 3000
      .waitForElementVisible '.WelcomeStacksView', 20000
      .click stackLink
      .waitForElementVisible '.StackEditor-OnboardingModal',20000