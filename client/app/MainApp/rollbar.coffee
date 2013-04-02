# Wrapper for pushing events to Rollbar.
logToExternal = KD.rollbar = (args) ->
  _rollbar.push args

# Push status events to Rollbar.
connections     = []
disconnections  = []

KD.remote.on 'connected', ->
  connections.push new Date

KD.remote.on 'disconnected', ->
  disconnections.push new Date

KD.remote.on 'reconnected', ->
  connections.push new Date
  data =
    connections:connections
    disconnections: disconnections
  logToExternal msg:"disconnected, then reconnected", data:data

KD.getSingleton('mainController').on "AccountChanged", (account) ->
  user = KD.whoami?().profile or KD.whoami()
  _rollbarParams.person =
    id: user.hash or user.nickname
    username: user.nickname
    name: user.firstName + " " + user.lastName
