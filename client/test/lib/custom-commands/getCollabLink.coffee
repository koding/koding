fs    = require 'fs'
utils = require '../utils/utils.js'


exports.command = getCollabLink = (browser, callback) ->

  path       = utils.getCollabLinkFilePath()
  isUrlFound = no

  getUrl = ->
    try
      url = fs.readFileSync path, 'utf8'

      if url
        clearInterval interval
        fs.unlinkSync path
        clearTimeout timer
        isUrlFound = yes
        callback? url

    catch
      console.log ' ✔ Checking for collaboration url...'

  interval = setInterval getUrl, 10000

  killer = ->
    unless isUrlFound
      console.log '>>>>>>>>>> Participant couldnt get the link in 6 minutes.'
      browser.end()

  timer = setTimeout killer, 360000

  return this
