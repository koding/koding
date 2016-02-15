helpers  = require '../helpers/helpers.js'
utils    = require '../utils/utils.js'
teamsHelpers = require '../helpers/teamshelpers.js'


module.exports =


  createPrivateChatWithNoParticipants: (browser) ->

  	user = teamsHelpers.loginTeam(browser)
  	teamsHelpers.createPrivateChat(browser)
  	browser.end()

