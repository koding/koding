fs      = require 'fs'
tempDir = require 'os-tmpdir'

exports.command = getCollabLink = (callback) ->

  path = "#{tempDir()}/collabLink.txt"

  getUrl = ->
    try
      url = fs.readFileSync path, 'utf8'

      if url
        clearInterval interval
        fs.unlinkSync path
        callback? url

    catch
      console.log ' ✔ Checking for collaboration url...'

  interval = setInterval getUrl, 10000

  return this
