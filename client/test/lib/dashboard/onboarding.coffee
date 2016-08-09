utils             = require '../utils/utils.js'
helpers           = require '../helpers/helpers.js'
teamsHelpers      = require '../helpers/teamshelpers.js'
onboardinghelper  = require '../helpers/onboardinghelpers.js'
async             = require 'async'

welcomeLink     = "#{helpers.getUrl(yes)}/Welcome"
WelcomeView     = '.WelcomeStacksView'

notFoundLink    = "#{WelcomeView} ul.bullets li:nth-of-type(8)"
notFoundPage     = '.HomeAppView--section.kd-cli'

user            = utils.getUser()

module.exports =

  dashboard: (browser) ->

    teamsHelpers.loginTeam browser, user, no , '', ->
      browser
        .url welcomeLink
        .pause 2000
        .waitForElementVisible WelcomeView, 20000

        #expect that this part will give error on wercker
        .click notFoundLink
        .waitForElementVisible notFoundPage, 20000


  after: (browser) ->
    browser.end()
