fs     = require "fs"
http   = require "https"
mime   = require "mime"
crypto = require "crypto"

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

  # split the ext, md5 just the url and write md5+ext to disk
  # md5 since some urls are too big and cause 'ENAMETOOLONG' error
  splitUrl = url.split(".")
  ext      = splitUrl.pop()
  noExt    = splitUrl.join(".")

  # arbitary limit to prevent ENAMETOOLONG errors
  if ext.length > 10
    ext = ext.substring(0, 10)

  # deal with extensions like:
  #   'com/LbobbpWTGJSa45Mhrb6g_y3YjLn5OthdnugrHZJQqom1eduFCnFmqdmOOZmUttP8hLg=h310'
  if ext.indexOf("com") > -1
    ext = "com"

  md5      = crypto.createHash("md5").update(noExt).digest("hex")
  filename = "#{imagePath}/#{md5}.#{ext}"

  serveFile = (filename, res)->
    fileStream = fs.createReadStream filename
    fileStream.pipe res

    mimeType = mime.lookup filename

    res.writeHead(200, { 'Content-Type': mimeType });

  if fs.existsSync filename
    return serveFile filename, res

  http.get fullUrl, (response)->
    response.pipe(fs.createWriteStream(filename)).on 'close', ->
      serveFile filename, res
