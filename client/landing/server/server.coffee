fs          = require 'fs'
bodyParser  = require 'body-parser'
STATIC_PATH = "#{__dirname}/../static/"
PORT        = 5000

do ->

  express = require 'express'
  gutil   = require 'gulp-util'

  app     = express()
  log     = (color, message) -> gutil.log gutil.colors[color] message

  app.use '/', express.static STATIC_PATH


  urlencodedParser = bodyParser.urlencoded({ extended: false })

  app.use bodyParser.urlencoded({ extended: false })


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


  app.get '*', (req, res) ->

    {url}      = req
    redirectTo = "/#!#{url}"

    res.header 'Location', redirectTo
    res.send 301

  app.listen PORT

  log 'green', "HTTP server for #{STATIC_PATH} is ready at localhost:#{PORT}"

  return
