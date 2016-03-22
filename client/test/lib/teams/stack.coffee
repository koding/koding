utils        = require '../utils/utils.js'
teamsHelpers = require '../helpers/teamshelpers.js'


module.exports =


  setCredential: (browser) ->

    teamsHelpers.loginTeam(browser)
    teamsHelpers.createStack(browser)
    teamsHelpers.createCredential(browser)
    browser.end()


  showCredential: (browser) ->

    teamsHelpers.loginTeam(browser)
    teamsHelpers.createStack(browser, yes)
    teamsHelpers.createCredential(browser, yes)
    browser.end()


  removeCredential: (browser) ->

    teamsHelpers.loginTeam(browser)
    teamsHelpers.createStack(browser, yes)
    teamsHelpers.createCredential(browser, no, yes)
    browser.end()


  useCredential: (browser) ->

    teamsHelpers.loginTeam(browser)
    teamsHelpers.createStack(browser, yes)
    teamsHelpers.createCredential(browser, no, no, yes)
    browser.end()

