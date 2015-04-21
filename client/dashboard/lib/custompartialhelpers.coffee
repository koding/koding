kd = require 'kd'
remote = require('app/remote').getInstance()


module.exports =

  ###*
   * Performs a request to backend to create a new
   * JCustomPartial object with given data
   *
   * @param {object} data       - data for a new object
   * @param {function} callback - it will be called after request is done
  ###
  createPartial: (data, callback = kd.noop) ->

    remote.api.JCustomPartials.create data, (err, partial) ->
      return kd.warn err  if err
      callback err, partial


  ###*
   * Performs a request to backend to get
   * JCustomPartial objects filtered by given query
   *
   * @param {object} query      - filter for DB request
   * @param {function} callback - it will be called after request is done
  ###
  getPartials: (query, callback = kd.noop) ->

    remote.api.JCustomPartials.some query, {}, (err, partials) ->
      return kd.warn err  if err
      callback err, partials