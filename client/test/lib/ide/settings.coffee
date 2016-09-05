helpers    = require '../helpers/helpers.js'
ideHelpers = require '../helpers/idehelpers.js'
utils = require '../utils/utils.js'
async = require 'async'
teamsHelpers = require '../helpers/teamshelpers.js'
ideSettings = require '../helpers/idesettingshelpers.js'
user = utils.getUser()
url = "#{helpers.getUrl(yes)}/IDE"

module.exports =

  before: (browser, done) ->

    targetUser1 = utils.getUser no, 1
    targetUser1.role = 'member'

    users = [
      targetUser1
    ]

    queue = [
      (next) ->
        teamsHelpers.inviteAndJoinWithUsers browser, users, (result) ->
          next null, result
      (next) ->
        teamsHelpers.buildStack browser, (res) ->
          browser.url url
          browser.pause 1, -> next null, res
      (next) ->
        ideHelpers.openNewFile browser, ->
          helpers.createFile browser, user, null, null, 'text.txt', (res) -> next null, res

    ]

    async.series queue, (err, result) ->
      done()  unless err


  settings: (browser, done) ->
    queue = [
      (next) ->
        ideSettings.enableAutoSave browser, (result) ->
          next null, result
      (next) ->
        ideSettings.toggleLineNumbers browser, user, (result) ->
          next null, result
      (next) ->
        ideSettings.showInvisibles browser, (result) ->
          next null, result
    ]

    async.series queue

  after: (browser) -> browser.end()
