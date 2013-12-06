koding         = require './bongo'
kodingApps     = {}
appCaches      = {}
kodingAppsJson = JSON.stringify kodingApps

module.exports = (req, res)->

  # TODO: Add in-memory cache functionality
  {app} = req.params

  # Lets fetch 3rd party apps
  {JNewApp} = koding.models
  JNewApp.one
    name     : app
    approved : yes
  , (err, app)->

    console.warn "Err:", err  if err
    _ret = {}

    if app

      _ret[app.name] =
        identifier   : app.identifier
        script       : app.url

    res.end JSON.stringify _ret
