kd           = require 'kd'
showError    = require 'app/util/showError'
doXhrRequest = require 'app/util/doXhrRequest'


module.exports = class LogsListController extends kd.ListViewController

  constructor: (options = {}, data) ->

    options.startWithLazyLoader or= yes
    options.noItemFoundWidget   or= new kd.CustomHTMLView
      partial  : 'No logs found!'
      cssClass : 'no-item-view'

    super options, data


  fetchLogs: (options = {})->

    return if @isFetching

    @removeAllItems()
    @showLazyLoader()

    @isFetching = yes

    @fetchLogsFromAPI options, (err, logs) =>
      return  if showError err
      @listLogs logs
      @isFetching = no


  fetchLogsFromAPI: (options, callback) ->

    type     = 'GET'
    endPoint = '/-/api/logs'
    args     = []

    if (scope = @getOption 'scope') and scope isnt 'all'
      args.push "scope=#{scope}"

    if q = options.query
      args.push "q=#{query}"

    if args.length > 0
      endPoint = "#{endPoint}?#{args.join ','}"

    doXhrRequest { endPoint, type }, (err, res) ->

      return callback err  if err

      { data: { logs } } = res
      logs.reverse()

      callback null, logs


  listLogs: (logs) ->

    if logs.length is 0 and @getItemCount() is 0
      @lazyLoader.hide()
      @showNoItemWidget()
      return

    @addItem log  for log in logs
    @lazyLoader.hide()


  loadView: ->

    super

    @hideNoItemWidget()
