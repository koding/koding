kd           = require 'kd'
doXhrRequest = require './doXhrRequest'

module.exports = ping = ->
  makePingRequest()
  kd.utils.repeat 30000, makePingRequest

makePingRequest = ->
  doXhrRequest { endPoint: '/api/social/presence/ping', type: 'GET' }, (err) ->
    console.log err  if err
