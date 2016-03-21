remote = require('../remote').getInstance()
logToExternal = require './logToExternal'
troubleshoot = require './troubleshoot'

# log ping times so we know if failure was due to user's slow
# internet or our internals timing out
module.exports = (name, options) ->
  troubleshoot (times) ->
    logToExternal "#{name} timed out", {
      options
      pings    : times
      protocol : remote.mq.ws.protocol
    }
