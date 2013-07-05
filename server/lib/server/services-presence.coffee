koding = require './bongo'

console.log koding.monitorPresence


parseServiceKey = require 'koding-service-key-parser'

allServices = {}

incService = (serviceKey, amount) ->
  serviceInfo = parseServiceKey serviceKey

  { serviceGenericName, serviceUniqueName } = serviceInfo

  allServices[serviceGenericName] ?= { seq: 0, services: {}}

  genericServices = allServices[serviceGenericName].services

  if genericServices[serviceUniqueName]?
  then genericServices[serviceUniqueName] += amount
  else genericServices[serviceUniqueName] = amount

  if genericServices[serviceUniqueName] is 0
    delete genericServices[serviceUniqueName]
  else if genericServices[serviceUniqueName] < 0
    console.error 'Negative service count!'

packageCleverly = (serviceName) -> Object.keys(serviceName)

setInterval ->
  console.log allServices
, 3000

koding.connect ->
  koding.monitorPresence
    join: (serviceKey) ->
      incService serviceKey, 1
    leave: (serviceKey) ->
      incService serviceKey, -1

module.exports = (req, res) ->
  {params:{service}, query} = req

  genericServices = allServices[service]

  { seq, services } = genericServices

  if query.all?
    res.send packageCleverly services
  else
    i = seq++ % services.length
    res.send [ i, seq, allServices ]
    # res.send services[i]





