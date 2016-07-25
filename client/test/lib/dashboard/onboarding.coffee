utils             = require '../utils/utils.js'
helpers           = require '../helpers/helpers.js'
teamsHelpers      = require '../helpers/teamshelpers.js'
onboardinghelper  = require '../helpers/onboardinghelpers.js'
async             = require 'async'

welcomeLink     = "#{helpers.getUrl(yes)}/Welcome"
WelcomeView     = '.WelcomeStacksView'
stackLink       = "#{WelcomeView} ul.bullets li:nth-of-type(1)"
stackEditor     = '.StackEditor-OnboardingModal'

notFoundLink    = "#{WelcomeView} ul.bullets li:nth-of-type(4)"
notFounPage     = '.HomeAppView--section.kd-cli'


module.exports =

  before: (browser, done) ->
    targetUser1 = utils.getUser no, 1
    targetUser1.role = 'member'
    users = targetUser1
    teamsHelpers.inviteAndJoinWithUsers browser, [users], (result) ->
      done()


  dashboard: (browser) ->

    browser
      .url welcomeLink
      .pause 2000
      .waitForElementVisible WelcomeView, 20000
      .click stackLink
      .waitForElementVisible stackEditor, 20000
      .url welcomeLink
      .pause 2000
      .waitForElementVisible WelcomeView, 20000

      #give error this part
      .click notFoundLink
      .waitForElementVisible notFounPage, 20000


  after: (browser) ->
    browser.end()
