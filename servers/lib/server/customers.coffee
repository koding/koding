{ get } = require (
  '../../../workers/social/lib/social/models/socialapi/requests.coffee'
)

async = require 'async'

module.exports = (req, res) ->
  koding              = require './bongo'
  { JMachine, JUser } = koding.models

  errMsg = (msg) ->
    {
      'description' : msg
      'error'       : 'bad_request'
    }

  { key } = req.query

  unless key
    return res.status(401).send errMsg 'key is required'

  # Hardcoding is wrong, however this key won't change
  # depending on environments, so there's point of
  # putting it in config : SA
  unless key is 'R1PVxSPvjvDSWdlPRVqRv8IdwXZB'
    return res.status(401).send errMsg 'key is wrong'

  url = '/payments/customers'

  get url, {}, (err, usernames) ->
    return res.status(400).send err  if err

    response = []
    queue    = []

    JUser.someData { username: { $in:usernames }, status: 'confirmed' }, {}, (err, cursor) ->
      return res.status(400).send err  if err

      cursor.toArray (err, usernames) ->
        return res.status(400).send err  if err

        usernames.forEach (username) ->
          queue.push (fin) -> JMachine.fetchByUsername username, (err, machines) ->
            if err
              fin()
            else
              slugs = []
              machines.forEach (machine) ->
                slugs.push  machine.data.slug  if machine.data.meta.alwaysOn

              response.push { 'username' : username, 'vms' : slugs }
              fin()

      async.parallel queue, -> res.status(200).send response
