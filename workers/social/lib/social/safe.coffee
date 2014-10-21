KodingError = require '../../error'

locks = []

lockProcess = (client)->
  {nickname} = client.connection.delegate.profile
  if (locks.indexOf nickname) > -1
    # console.log "[LOCKER] User #{nickname} requested to acquire lock again!"
    return false
  else
    # console.log "[LOCKER] User #{nickname} locked."
    locks.push nickname
    return yes

unlockProcess = (client)->
  {nickname} = client.connection.delegate.profile
  t = locks.indexOf nickname
  if t > -1
    # console.log "[UNLOCKER] User #{nickname} unlocked."
    locks[t..t] = []
  # else
  #   console.log "[UNLOCKER] User #{nickname} was not locked, nothing to do."

safe = do -> (fn) ->

  (client, rest..., _callback) ->

    unless typeof _callback is 'function'
      _callback = (err)-> console.error "Unhandled error:", err.message

    unless lockProcess client
      return _callback new KodingError \
        "There is a process on-going, try again later.", "Busy"

    callback = (rest...)->
      unlockProcess client
      _callback rest...

    fn.call this, client, rest..., callback


module.exports = { safe }
