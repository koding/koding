
do ->

  express = require 'express'
  gutil   = require 'gulp-util'

  app     = express()
  log     = (color, message) -> gutil.log gutil.colors[color] message

  app.use '/', express.static "#{__dirname}/../static"

  app.get '*', (req, res) ->
    {url}      = req
    console.log url, "/#!#{url}"
    redirectTo = "/#!#{url}"

    res.header 'Location', redirectTo
    res.send 301

  app.listen 3000

  log 'green', "HTTP server for #{__dirname}/static/ is ready at localhost:3000"

  return
