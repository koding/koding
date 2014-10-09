fs          = require 'fs'
bodyParser  = require 'body-parser'
STATIC_PATH = "#{__dirname}/../static/"
PORT        = 5000
crypto      = require 'crypto'
request     = require 'request'

{exec}      = require 'child_process'

module.exports = (siteName)->

  express = require 'express'
  gutil   = require 'gulp-util'

  app     = express()
  log     = (color, message) -> gutil.log gutil.colors[color] message

  app.use '/', express.static STATIC_PATH


  urlencodedParser = bodyParser.urlencoded({ extended: false })

  app.use bodyParser.urlencoded({ extended: false })

  app.post '/FetchGravatarInfo', (req, res) ->
    {email} = req.body
    console.log "Gravatar info request for: #{email}"

    _hash    = (crypto.createHash('md5').update(email.toLowerCase().trim()).digest("hex")).toString()
    _url     = "https://www.gravatar.com/#{_hash}.json"
    _request =
      url     : _url
      headers :
        'User-Agent': 'request'

    request _request, (err, response, body) ->
      if body isnt "User not found"
        gravatar = JSON.parse body
        console.log gravatar
        res.status(200).send(gravatar)

      else
        res.status(400).send(body)


    # data = '{"entry":[{"id":"5390782","hash":"02e68fe6ba0d08c7ea5b63320beedc46","requestHash":"dyasar","profileUrl":"http:\/\/gravatar.com\/dyasar","preferredUsername":"dyasar","thumbnailUrl":"http:\/\/0.gravatar.com\/avatar\/02e68fe6ba0d08c7ea5b63320beedc46","photos":[{"value":"http:\/\/0.gravatar.com\/avatar\/02e68fe6ba0d08c7ea5b63320beedc46","type":"thumbnail"}],"name":{"givenName":"Devrim","familyName":"Yasar","formatted":"Devrim Yasar"},"displayName":"Devrim","urls":[]}]}'

    # res.status(400).send(JSON.parse data)


  app.post '/Login', (req, res) ->

    {username, password} = req.body  if req.body
    console.log "Login request for: #{username}/#{password}"

    if 'wrong' in [username, password]
    then res.status(403).send 'Wrong password!'
    else res.status(200).send null


  app.post '/Register', (req, res) ->

    {email, username, password} = req.body  if req.body
    console.log "Registration request for: #{email}/#{username}/#{password}"

    if 'wrong' in [username, password]
    then res.status(403).send 'Wrong password!'
    else res.status(200).send null


  app.get '/:name?', (req, res, next) ->

    {params : {name}} = req

    folders  = (folder for folder in fs.readdirSync('./') when fs.statSync(folder).isDirectory())
    sites    = folders.filter (folder) -> folder.search(/^site\./) is 0

    if "site.#{name}" in sites
      console.log 'serving', name
      return res.status(200).send (require './index.parser') name
    else
      next()

  app.get '/', (req, res, next) ->

    return res.status(200).send (require './index.parser') siteName


  app.get '*', (req, res) ->

    {url}      = req
    redirectTo = "/#!#{url}"

    res.header 'Location', redirectTo
    res.status(301).end()

  app.listen PORT

  log 'green', "HTTP server for #{STATIC_PATH} is ready at localhost:#{PORT}"

  return
