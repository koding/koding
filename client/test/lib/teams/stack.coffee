utils        = require '../utils/utils.js'
teamsHelpers = require '../helpers/teamshelpers.js'


module.exports =


  setCredential: (browser) ->

    teamsHelpers.loginTeam(browser)
    teamsHelpers.createStack(browser, yes)
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


  buildStack: (browser) ->

    teamsHelpers.loginTeam(browser)
    teamsHelpers.createStack(browser, yes)
    teamsHelpers.createCredential(browser, no, no, yes)
    teamsHelpers.saveTemplate(browser)
    teamsHelpers.buildStack(browser)
    teamsHelpers.destroyEverything(browser)
    browser.end()


  editStack: (browser) ->

    teamsHelpers.loginTeam(browser)
    teamsHelpers.createStack(browser, yes)
    teamsHelpers.createCredential(browser, no, no, yes)
    teamsHelpers.saveTemplate(browser, no)
    teamsHelpers.editStack(browser, no)
    browser.end()


  openAndCloneStack: (browser) ->

    teamsHelpers.loginTeam(browser)
    teamsHelpers.createStack(browser, yes)
    teamsHelpers.createCredential(browser, no, no, yes)
    teamsHelpers.saveTemplate(browser, no)
    teamsHelpers.editStack(browser, yes)
    browser.end()


  deleteStackTemplate: (browser) ->

    teamsHelpers.loginTeam(browser)
    teamsHelpers.createStack(browser, yes)
    teamsHelpers.createCredential(browser, no, no, yes)
    teamsHelpers.saveTemplate(browser, no, no)
    teamsHelpers.deleteStack(browser)
    browser.end()