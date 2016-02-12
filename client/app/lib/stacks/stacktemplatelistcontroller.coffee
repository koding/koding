kd                          = require 'kd'
remote                      = require('app/remote').getInstance()
whoami                      = require 'app/util/whoami'
getGroup                    = require 'app/util/getGroup'
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
    { viewType  }      = @getOptions()

    currentGroup = getGroup()
    query        = { group: currentGroup.slug }

    query.originId = whoami()._id  unless viewType is 'group'

    # TODO Add Pagination here ~ GG
    # TMS-1919: This is TODO needs to be done ~ GG
    JStackTemplate.some query, { limit: 30 }, (err, stackTemplates) =>
      return @onItemsLoaded err  if err
      kd.singletons.computeController.fetchStacks (err, stacks) =>
        @onItemsLoaded err, stackTemplates, stacks


  onItemsLoaded: (err, stackTemplates = [], stacks = []) ->

    @hideLazyLoader()

    return if showError err, \
      KodingError : "Failed to fetch stackTemplates, try again later."

    currentGroup = getGroup()
    { viewType } = @getOptions()

    stackTemplates.map (template) ->
      template.isDefault = template._id in (currentGroup.stackTemplates or [])
      template.inUse     = Boolean stacks.find (stack) -> stack.baseStackId is template._id

    if viewType is 'group'
      stackTemplates = stackTemplates.filter (template) -> template.accessLevel is 'group'

    @instantiateListItems stackTemplates

    @emit 'ItemsLoaded', stackTemplates


  loadView: ->

    super

    view = @getView()
    view.on 'ItemDeleted', (item) =>
      @removeItem item
      @noItemView.show()  if @listView.items.length is 0
