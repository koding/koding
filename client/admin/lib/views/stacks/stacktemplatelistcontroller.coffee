kd                          = require 'kd'
remote                      = require('app/remote').getInstance()

showError                   = require 'app/util/showError'
AccountListViewController   = require 'account/controllers/accountlistviewcontroller'


module.exports = class StackTemplateListController extends AccountListViewController


  constructor: (options = {}, data) ->

    options.noItemFoundText ?= "You have no stack template"
    super options, data

    @loadItems()


  loadItems: ->

    @removeAllItems()
    @showLazyLoader()

    { JStackTemplate } = remote.api

    JStackTemplate.some {}, { limit: 30 }, (err, stackTemplates) =>

      @hideLazyLoader()

      return if showError err, \
        KodingError : "Failed to fetch stackTemplates, try again later."

      @instantiateListItems stackTemplates


  loadView: ->

    super

    view = @getView()
    view.on 'ItemDeleted', (item) =>
      @removeItem item
      @noItemView.show()  if @listView.items.length is 0
