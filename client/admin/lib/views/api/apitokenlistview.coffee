kd                   = require 'kd'
KDView               = kd.View
KDCustomHTMLView     = kd.CustomHTMLView
getGroup             = require 'app/util/getGroup'
APITokenItemView     = require './apitokenitemview'
KodingListController = require 'app/kodinglist/kodinglistcontroller'

module.exports = class APITokenListView extends KDView

  constructor: (options = {}, data) ->

    options.cssClass   = 'members-commonview'

    super options, data

    @createListController()


  createListController: ->

    @listController     = new KodingListController
      limit             : 20
      itemClass         : APITokenItemView
      loadWithScroll    : no
      noItemFoundWidget : new KDCustomHTMLView
        partial         : 'No API tokens found!'
        cssClass        : 'no-item-view'
      fetcherMethod     : (query, options, callback) ->
        getGroup().fetchApiTokens (err, apiTokens)  ->
          callback err, apiTokens

    @listView = @listController.getView()


  viewAppended: ->

    @addSubView @listView
