kd                = require 'kd'
KDView            = kd.View
remote            = require('app/remote').getInstance()
ApiTokenItemView  = require './apitokenitemview'
KDCustomHTMLView  = kd.CustomHTMLView
ApiListController = require './apilistcontroller'


module.exports = class ApiTokenListView extends KDView

  constructor: (options = {}, data) ->

    options.cssClass            = 'members-commonview'
    options.itemLimit          ?= 20
    options.noItemFoundWidget or= new KDCustomHTMLView

    super options, data

    @createListController()


  createListController: ->

    @listController = new ApiListController
      viewOptions :
        wrapper   : yes
        itemClass : ApiTokenItemView

    @listView = @listController.getView()
    @listController.fetchApiTokens()


  viewAppended: ->

    @addSubView @listView


  refresh: ->

    @resetListItems()
    @fetchApiTokens()
