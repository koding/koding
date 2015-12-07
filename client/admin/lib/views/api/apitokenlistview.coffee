kd                = require 'kd'
KDView            = kd.View
remote            = require('app/remote').getInstance()
APITokenList      = require './apitokenlist'
APITokenItemView  = require './apitokenitemview'
KDCustomHTMLView  = kd.CustomHTMLView
APIListController = require './apilistcontroller'


module.exports = class APITokenListView extends KDView

  constructor: (options = {}, data) ->

    options.cssClass   = 'members-commonview'
    options.itemLimit ?= 20

    super options, data

    @createListController()


  createListController: ->

    @list           = new APITokenList
    @listController = new APIListController
      view    : @list
      wrapper : yes

    @listView = @listController.getView()
    @listController.fetchAPITokens()


  viewAppended: ->

    @addSubView @listView

