fs          = require 'fs'
STATIC_PATH = "#{__dirname}/../static/"
PORT        = 80
bodyParser  = require 'body-parser'
crypto      = require 'crypto'
request     = require 'request'
basicAuth   = require 'basic-auth-connect'
{exec}      = require 'child_process'

module.exports = (siteName, port)->

  port   ?= PORT

  express = require 'express'
  gutil   = require 'gulp-util'

  app     = express()
  log     = (color, message) -> gutil.log gutil.colors[color] message

  app.use '/', express.static STATIC_PATH

  app.use bodyParser.urlencoded({ extended: false })

  app.use basicAuth 'koding', 'hackathon'  if port is 80

  app.post '/Hackathon2014/Apply', (req, res) ->
    res.status(200).send {
      totalApplicants    : 14812
      approvedApplicants : 5613
      isApplicant        : yes
      deadline           : new Date '20 November 2014'
      prize              : 10000
      cap                : 50000
    }


  app.post '/Gravatar', (req, res) ->
    {email} = req.body
    console.log "Gravatar info request for: #{email}!!!"

    _hash    = (crypto.createHash('md5').update(email.toLowerCase().trim()).digest("hex")).toString()
    _url     = "https://www.gravatar.com/#{_hash}.json"
    _request =
      url     : _url
      headers : 'User-Agent' : 'request'

    request _request, (err, response, body) ->
      if body isnt "User not found"
        gravatar = JSON.parse body
        res.status(200).send(gravatar)

      else
        res.status(400).send(body)


  app.post '/Validate/Username/:username?', (req, res) ->

    return res.status(200).send
      forbidden  : no
      kodingUser : no


  app.post '/Validate/Email/:email?', (req, res) ->

    return res.status(200).send yes


  app.post '/Login', (req, res) ->

    {username, password} = req.body  if req.body
    console.log "Login request for: #{username}/#{password}"

    if 'wrong' in [username, password]
    then res.status(403).send 'Wrong password!'
    else res.status(200).end()


  app.post '/Register', (req, res) ->

    {email, username, password} = req.body  if req.body
    console.log "Registration request for: #{email}/#{username}/#{password}"

    if 'wrong' in [username, password]
    then res.status(403).send 'Wrong password!'
    else res.status(200).end()


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

  app.listen port

  log 'green', "HTTP server for #{STATIC_PATH} is ready at localhost:#{PORT}"

  return
