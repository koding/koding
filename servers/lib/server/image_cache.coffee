fs     = require 'fs'
http   = require 'https'
mime   = require 'mime'
crypto = require 'crypto'
parser = require 'url'

{
  embedly : {
    apiKey
  }
} = KONFIG

imagePath = 'embedly_cache'

fs.mkdir imagePath, null, ->

module.exports = (req, res) ->
  { endpoint, grow, width, height, url } = req.query

  unless url
    return res.status(400).send 'Url is not set'

  fullUrl = "https://i.embed.ly/1/display/#{endpoint}?" +
             "width=#{width}&" +
             "height=#{height}&" +
             "key=#{apiKey}&" +
             "url=#{encodeURIComponent(url)}"

  url   = parser.parse url

  unless url.pathname?
    return res.status(500).end()

  ext   = url.pathname.split('.')[-1] or 'jpeg'
  noExt = "#{url.host}#{url.pathname}"

  # arbitary limit to prevent ENAMETOOLONG errors
  if ext.length > 20
    ext = ext.substring(0, 20)

  # deal with extensions like:
  #   'com/LbobbpWTGJSa45Mhrb6g_y3YjLn5OthdnugrHZJQqom1eduFCnFmqdmOOZmUttP8hLg=h310'
  if ext.indexOf('com') > -1
    ext = 'jpeg'

  # replace nonalphanumeric characters
  ext = ext.replace(/\W+/g, '')

  md5 = crypto.createHash('md5')
  for i in [noExt, width, height]
    md5.update(i)  if typeof i is 'string'

  digest   = md5.digest('hex')
  filename = "#{imagePath}/#{digest}.#{ext}"

  serveFile = (filename, res) ->
    fileStream = fs.createReadStream filename
    fileStream.pipe res

    mimeType = mime.lookup filename

    res.writeHead(200, { 'Content-Type': mimeType })

  if fs.existsSync filename
    return serveFile filename, res

  http.get fullUrl, (response) ->
    response.pipe(fs.createWriteStream(filename)).on 'close', ->
      serveFile filename, res
