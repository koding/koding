kd                = require 'kd'
KDView            = kd.View
remote            = require('app/remote').getInstance()
ApiTokenList      = require './apitokenlist'
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

    @list           = new ApiTokenList
    @listController = new ApiListController
      view    : @list
      wrapper : yes

    @listView = @listController.getView()
    @listController.fetchApiTokens()


  viewAppended: ->

    @addSubView @listView


  refresh: ->

    @resetListItems()
    @fetchApiTokens()
