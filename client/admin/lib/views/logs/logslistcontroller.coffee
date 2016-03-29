kd                   = require 'kd'
LogsItemView         = require './logsitemview'
doXhrRequest         = require 'app/util/doXhrRequest'
KodingListController = require 'app/kodinglist/kodinglistcontroller'

module.exports = class LogsListController extends KodingListController

  constructor: (options = {}, data) ->

    options.itemClass           or= LogsItemView
    options.viewOptions         or= { wrapper : yes }
    options.noItemFoundText     or= 'No logs found!'
    options.fetcherMethod         = (query, fetchOptions, callback) =>
      doXhrRequest @getXHROptions(), (err, res) ->
        return callback err  if err
        { data: { logs } } = res
        callback null, logs

    super options, data


  getXHROptions: (options = {}) ->

    type     = 'GET'
    endPoint = '/-/api/logs'
    args     = []

    if (scope = @getOption 'scope') and scope isnt 'all'
      args.push "scope=#{scope}"

    if q = options.query
      args.push "q=#{options.query}"

    if args.length > 0
      endPoint = "#{endPoint}?#{args.join ','}"

    return { endPoint, type }
