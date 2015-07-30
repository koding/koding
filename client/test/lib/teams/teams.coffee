helpers  = require '../helpers/helpers.js'
utils    = require '../utils/utils.js'
teamsHelpers = require '../helpers/teamshelpers.js'


module.exports =


  createTeam: (browser) ->

    user = utils.getUser(yes)

    browser.url helpers.getUrl()
    browser.maximizeWindow()

    helpers.setCookie(browser, 'team-access', 'true')

    teamsHelpers.openTeamsPage(browser)
    teamsHelpers.fillSignUpFormOnTeamsHomePage(browser, user)
    teamsHelpers.enterTeamURL(browser)
    teamsHelpers.enterEmailDomains(browser)
    teamsHelpers.enterInvites(browser)
    teamsHelpers.fillUsernamePasswordForm(browser, user)
    teamsHelpers.setupStackPage(browser)
    teamsHelpers.congratulationsPage(browser)
    teamsHelpers.loginToTeam(browser, user)

    browser.end()
