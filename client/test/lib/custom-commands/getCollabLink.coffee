fs      = require 'fs'
tempDir = require 'os-tmpdir'

exports.command = getCollabLink = (browser, callback) ->

  path       = "#{tempDir()}/collabLink.txt"
  isUrlFound = no

  getUrl = ->
    try
      url = fs.readFileSync path, 'utf8'

      if url
        clearInterval interval
        clearTimeout timer
        fs.unlinkSync path
        isUrlFound = yes
        console.log '>>>>>>>>>> Collaboration URL is', url
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
