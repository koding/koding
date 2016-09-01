helpers    = require '../helpers/helpers.js'
ideHelpers = require '../helpers/idehelpers.js'
utils = require '../utils/utils.js'
async = require 'async'
teamsHelpers = require '../helpers/teamshelpers.js'
ideSettings = require '../helpers/idesettings.js'

module.exports =

  before: (browser, done) ->

    targetUser1 = utils.getUser no, 1
    targetUser1.role = 'member'

    users = [
      targetUser1
    ]

    queue = [
      (next) ->
        teamsHelpers.loginTeam browser
        browser.pause 2000, (res)->
          next null, res 
      (next) ->
        teamsHelpers.buildStack browser, (res) ->
          next null, res

      # go to IDE url
      (next) ->
        teamUrl = helpers.getUrl yes
        url = "#{teamUrl}/IDE"
        browser.url url, -> next null
    ]

    async.series queue, (err, result) ->
      done()  unless err


  settings: (browser, done) ->
    user = utils.getUser()

    queue = [
      (next) ->
        ideSettings.enableAutosave browser, (res) -> next null
      (next) ->
        ideSettings.toggleLineNumbers browser, user, (res) -> next null

  	]

    async.series queue

  # after: (browser) -> browser.end()
