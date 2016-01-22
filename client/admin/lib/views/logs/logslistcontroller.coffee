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


  fetchLogs: ->

    return if @isFetching

    @removeAllItems()
    @showLazyLoader()

    @isFetching = yes

    @fetchLogsFromAPI {}, (err, res) =>

      return  if showError err

      { data: { logs }} = res
      @listLogs logs

      @isFetching = no


  fetchLogsFromAPI: (options, callback) ->

    type     = 'GET'
    endPoint = '/-/api/logs'

    doXhrRequest { endPoint, type }, (err, res) ->
      console.log ">>>>>>", err, res
      callback err, res


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
