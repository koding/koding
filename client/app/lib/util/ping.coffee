kd           = require 'kd'
doXhrRequest = require './doXhrRequest'

kd.utils.repeat 30000, ->
  doXhrRequest { endPoint: '/api/social/presence/ping', type: 'GET' }, (err) ->
    console.log err  if err
