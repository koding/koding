kd = require 'kd'
remote = require('app/remote').getInstance()


module.exports =

  createPartial: (data, callback = kd.noop) ->

    remote.api.JCustomPartials.create data, (err, partial) ->
      return kd.warn err  if err
      callback err, partial


  getPartials: (query, callback = kd.noop) ->

    remote.api.JCustomPartials.some query, {}, (err, partials) ->
      return kd.warn err  if err
      callback err, partials