{ argv } = require 'optimist'

koding = require './bongo'

parseServiceKey = require 'koding-service-key-parser'

allServices = {}

incService = (serviceKey, amount) ->
  serviceInfo = parseServiceKey serviceKey

  { serviceGenericName, serviceUniqueName } = serviceInfo

  fetchHostname serviceGenericName, serviceUniqueName, (err, hostname) ->

    allServices[serviceGenericName] ?= { seq: 0, services: {} }

    genericServices = allServices[serviceGenericName].services

    if genericServices[serviceUniqueName]?
    then genericServices[serviceUniqueName].amount += amount
    else genericServices[serviceUniqueName] = { amount, hostname }

    if genericServices[serviceUniqueName].amount is 0
      delete genericServices[serviceUniqueName]
    else if genericServices[serviceUniqueName].amount < 0
      console.error 'Negative service count!'

koding.connect ->
  koding.monitorPresence
    join: (serviceKey) ->
      incService serviceKey, 1
    leave: (serviceKey) ->
      incService serviceKey, -1

fetchHostname = (serviceGenericName, serviceUniqueName, callback) ->
  if 'broker' is serviceGenericName and not KONFIG.broker.useKontrold
    process.nextTick -> callback null,
      if KONFIG.broker.webPort?
      then "#{ KONFIG.broker.webHostname }:#{ KONFIG.broker.webPort }"
      else KONFIG.broker.webHostname
  else
    (koding.getClient().collection 'jKontrolWorkers')
      .findOne {
        serviceUniqueName
        hostname:///^#{ serviceGenericName }///
        status: 0
      }, { hostname: 1 }, (err, worker) ->
        return callback err  if err?
        callback null, worker?.hostname ? null

module.exports = (req, res) ->
  {params:{service}, query} = req

  protocol = KONFIG.broker.webProtocol ? 'https:'

  genericServices = allServices[service]

  services = Object.keys(genericServices.services).map( (k) ->
    { hostname } = genericServices.services[k]
    unless hostname?
      console.warn """
        Could not find that hostname:
        #{k}
        #{require('util').inspect genericServices.services[k]}
        """
    return hostname
  ).filter Boolean

  if query.all?
    res.send services.map (hostname) -> "#{ protocol }//#{ hostname }"
  else
    i = genericServices.seq++ % services.length
    res.set "Content-Type", "text/json"
    res.send "\"#{ protocol }//#{ services[i] }\""
