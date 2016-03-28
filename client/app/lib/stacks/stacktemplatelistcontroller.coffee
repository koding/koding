kd                          = require 'kd'
remote                      = require('app/remote').getInstance()
whoami                      = require 'app/util/whoami'
getGroup                    = require 'app/util/getGroup'
showError                   = require 'app/util/showError'
async                       = require 'async'
KodingListController        = require 'app/kodinglist/kodinglistcontroller'


module.exports = class StackTemplateListController extends KodingListController


  constructor: (options = {}, data) ->

    options.noItemFoundText ?= 'You currently have no stack template'
    super options, data

    @loadItems()


  loadItems: ->

    @showLazyLoader()

    { JStackTemplate } = remote.api
    { viewType }       = @getOptions()

    currentGroup   = getGroup()
    query          = { group: currentGroup.slug }
    query.originId = whoami()._id  unless viewType is 'group'

    queue = [
      (next) ->
        currentGroup.canEditGroup (err, success) -> next null, success
      (next) ->
        # TODO Add Pagination here ~ GG
        # TMS-1919: This is TODO needs to be done ~ GG
        JStackTemplate.some query, { limit: 30 }, next
      (next) ->
        kd.singletons.computeController.fetchStacks next
    ]

    async.series queue, (err, results) =>
      return @onItemsLoaded err  if err
      [canEditGroup, stackTemplates, stacks] = results
      @onItemsLoaded null, stackTemplates, stacks, canEditGroup


  onItemsLoaded: (err, stackTemplates = [], stacks = [], canEditGroup) ->

    @removeAllItems()
    @hideLazyLoader()

    return if showError err, \
      { KodingError : 'Failed to fetch stackTemplates, try again later.' }

    currentGroup = getGroup()
    { viewType } = @getOptions()

    stackTemplates.map (template) ->
      template.isDefault       = template._id in (currentGroup.stackTemplates or [])
      template.inUse           = Boolean stacks.find (stack) -> stack.baseStackId is template._id
      template.canForcedReinit = canEditGroup and template.accessLevel is 'group'

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
