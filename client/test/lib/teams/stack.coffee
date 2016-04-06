utils        = require '../utils/utils.js'
teamsHelpers = require '../helpers/teamshelpers.js'


module.exports =


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
    teamsHelpers.saveTemplate(browser, no, no, no)
    teamsHelpers.editStack(browser)
    browser.isStackBuilt = yes
    teamsHelpers.destroyEverything(browser)
    browser.end()


  cloneStack: (browser) ->

    teamsHelpers.loginTeam(browser)
    teamsHelpers.createStack(browser, yes)
    teamsHelpers.createCredential(browser, no, no, yes)
    teamsHelpers.saveTemplate(browser, no, no, no)
    teamsHelpers.editStack(browser, yes)
    browser.isStackBuilt = yes
    teamsHelpers.destroyEverything(browser)
    browser.end()


  deleteStackTemplate: (browser) ->

    teamsHelpers.loginTeam(browser)
    teamsHelpers.createStack(browser, yes)
    teamsHelpers.createCredential(browser, no, no, yes)
    teamsHelpers.saveTemplate(browser, no, no, no)
    teamsHelpers.deleteStack(browser)
    browser.isStackBuilt = yes
    teamsHelpers.destroyEverything(browser)
    browser.end()