kd                          = require 'kd'
remote                      = require('app/remote').getInstance()

showError                   = require 'app/util/showError'
AccountListViewController   = require 'account/controllers/accountlistviewcontroller'


module.exports = class StackTemplateListController extends AccountListViewController


  constructor: (options = {}, data) ->

    options.noItemFoundText ?= "You currently have no stack template"
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

      { groupsController } = kd.singletons
      currentGroup = groupsController.getCurrentGroup()

      stackTemplates.map (template) ->
        console.log template._id, currentGroup.stackTemplates
        template.inuse = template._id in (currentGroup.stackTemplates or [])

      @instantiateListItems stackTemplates


  loadView: ->

    super

    view = @getView()
    view.on 'ItemDeleted', (item) =>
      @removeItem item
      @noItemView.show()  if @listView.items.length is 0
