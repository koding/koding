helpers  = require '../helpers/helpers.js'
utils    = require '../utils/utils.js'
teamsHelpers = require '../helpers/teamshelpers.js'


module.exports =


  sendComment: (browser) ->

    user = teamsHelpers.loginTeam(browser)
    teamsHelpers.createChannel(browser, user)
    teamsHelpers.sendComment(browser)
    browser.end()


