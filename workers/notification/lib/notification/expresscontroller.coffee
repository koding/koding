cors = require 'cors'
http = require 'http'

helmet = require 'helmet'

express    = require 'express'
{ argv }   = require 'optimist'
bodyParser = require 'body-parser'

KONFIG = require 'koding-config-manager'


module.exports = class ExpressController


  constructor: (options = {}) ->

    { @delegate } = options

    @log = @delegate.log.bind @delegate

    @_app = express()

    @_app.use bodyParser.json { limit: '100kb' }
    @_app.use helmet()
    @_app.use cors()

    @_app.get  '/notify',                  @_handleStatusRequest.bind this
    @_app.post '/dispatcher_notify_user',  @_handleSendNotification 'user'
    @_app.post '/dispatcher_notify_group', @_handleSendNotification 'group'


  startServer: (socket) ->

    @_server = http.createServer @_app
    socket.installHandlers @_server, { prefix: '/notify/subscribe' }
    @_server.listen argv.p

    return @_server


  _handleSendNotification: (scope) -> (req, res) =>

    @log "got hit on send -- #{scope}", req.body

    { groupName, account, body } = req.body

    if scope is 'group'
      if groupName
        routingKey = groupName
      else
        return res.sendStatus 500

    else if scope is 'user'
      if (groupName = body?.context) and (username = account?.nick)
        routingKey = "#{groupName}:#{username}"
      else
        return res.sendStatus 500

    @delegate.sendNotification routingKey, body

    res.sendStatus 200


  _handleStatusRequest: (req, res) ->

    res.send """
      <pre>
        NotificationWorker #{argv.i ? 0} is #{if @delegate.isReady() then '' else 'not '}ready
        Connections: #{JSON.stringify @delegate._verifiedConnections}
        Routes: #{JSON.stringify @delegate._verifiedRoutes}
      </pre>
    """
