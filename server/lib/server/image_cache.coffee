fs   = require "fs"
http = require "https"
mime = require "mime"

{
  embedly : {
    apiKey
  }
} = KONFIG

imagePath = "embedly_cache"

fs.mkdir imagePath, null, ->

module.exports = (req, res) ->
  {endpoint, grow, width, height, url} = req.query

  fullUrl  = "https://i.embed.ly/1/display/#{endpoint}?" +
             "width=#{width}&" +
             "height=#{height}&" +
             "key=#{apiKey}&" +
             "url=#{url}"

  filename = "#{imagePath}/#{url.split('/').join('_')}"

  serveFile = (filename, res)->
    fileStream = fs.createReadStream filename
    fileStream.pipe res

    mimeType = mime.lookup filename

    res.writeHead(200, {'Content-Type': mimeType });

  if fs.existsSync filename
    return serveFile filename, res

  http.get fullUrl, (response)->
    response.pipe(fs.createWriteStream(filename)).on 'close', ->
      serveFile filename, res
