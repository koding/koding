kd                   = require 'kd'
remote               = require('app/remote').getInstance()
getGroup             = require 'app/util/getGroup'
showError            = require 'app/util/showError'
KDCustomHTMLView     = kd.CustomHTMLView
KDListViewController = kd.ListViewController


module.exports = class ApiListController extends KDListViewController

  constructor: (options = {}, data) ->

    options.startWithLazyLoader or= yes
    options.lazyLoadThreshold   or= .99
    options.lazyLoaderOptions   or= {}
    options.lazyLoaderOptions   or=
      spinnerOptions :
        size : width : 28
    options.noItemFoundWidget   or= new KDCustomHTMLView
      partial  : 'No api tokens found!'
      cssClass : 'no-item-view'

    super options, data


  fetchApiTokens: ->

    return if @isFetching

    @isFetching = yes

    getGroup().fetchApiTokens (err, apiTokens) =>
      return @handleError err  if err

      @listApiTokens apiTokens
      @isFetching = no


  listApiTokens: (apiTokens) ->

    if apiTokens.length is 0 and @getItemCount() is 0
      @lazyLoader.hide()
      @showNoItemWidget()
      return

    @addItem apiToken  for apiToken in apiTokens
    @lazyLoader.hide()


  loadView: ->

    super

    view = @getView()
    console.log view
    view.on 'ItemDeleted', (item) =>
      @removeItem item
      @noItemView.show()  if @listView.items.length is 0
