# Wrapper for pushing events to Rollbar.
logToExternal = KD.rollbar = (args) ->
  args.user = KD.whoami?().profile
  _rollbar.push(args)

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
