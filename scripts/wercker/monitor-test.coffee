_ = require 'underscore'

TIMEOUT  = 6 * 60 * 1000
INTERVAL = 1 * 60 * 1000

childs   = {}
monitors = {}


monitor = (child) ->

  now = Date.now()

  timestamp = childs[child.pid]
  expired   = (now - timestamp) > TIMEOUT

  return  unless expired

  child.kill 'SIGTERM'


remove = (child) ->

  id = child.pid
  childs[id] = null
  clearInterval monitors[id]
  monitors[id] = null


add = (child, callback) ->

  childs[child.pid] = Date.now()

  child.stdout.on 'data', do (child) ->
    return _.debounce ->
      childs[child.pid] = Date.now()
      callback()
    , 10000

  child.on 'exit', do (child) ->
    return (code, signal) ->
      remove child

  interval = setInterval do (child) ->

    return ->
      monitor child

  , INTERVAL

  monitors[child.pid] = interval


module.exports = add
