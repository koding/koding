fs    = require 'fs'
utils = require '../utils/utils.js'


exports.command = getMemberInvitation = (browser, callback) ->

  path       = utils.getMemberInvitationPath()
  isStatusFound = no

  getStatus = ->
    try
      status = fs.readFileSync path, 'utf8'

      if status
        clearInterval interval
        clearTimeout timer
        isStatusFound = yes
        console.log '>>>>>>>>>> Participant joined to team'
        callback? status

    catch
      console.log ' ✔ waiting participant join to team ...'

  interval = setInterval getStatus, 10000

  killer = ->
    unless isStatusFound
      console.log '>>>>>>>>>> Participant couldnt joined to team in 6 minutes.'
      browser.end()

  timer = setTimeout killer, 360000

  return this
