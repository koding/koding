helpers  = require '../helpers/helpers.js'
utils    = require '../utils/utils.js'
teamsHelpers = require '../helpers/teamshelpers.js'


module.exports =


  createChannel: (browser) ->

    user = teamsHelpers.loginTeam(browser)
    teamsHelpers.createChannel(browser, user)
    browser.end()


  sendComment: (browser) ->

    user = teamsHelpers.loginTeam(browser)
    teamsHelpers.createChannel(browser, user)
    teamsHelpers.sendComment(browser)
    browser.end()


  checkChannelList: (browser) ->

    user = teamsHelpers.loginTeam(browser)
    teamsHelpers.createChannelsAndCheckList(browser, user)
    browser.end()

