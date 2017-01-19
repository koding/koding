kd                    = require 'kd'
showError             = require 'app/util/showError'
sortStacks            = require 'app/util/sortEnvironmentStacks'
ComputeHelpers        = require '../providers/computehelpers'
EnvironmentListItem   = require './environmentlistitem'
KodingListController  = require 'app/kodinglist/kodinglistcontroller'
Tracker               = require 'app/util/tracker'
getGroup              = require 'app/util/getGroup'


module.exports = class EnvironmentListController extends KodingListController


  constructor: (options = {}, data) ->

    options.wrapper         ?= no
    options.itemClass       ?= EnvironmentListItem
    options.scrollView      ?= no
    options.noItemFoundText ?= "You don't have any stacks"

    options.fetcherMethod    = (query, options, callback) ->
      kd.singletons.computeController.fetchStacks (err, stacks) -> callback err, stacks

    super options, data


  bindEvents: ->

    super

    { computeController } = kd.singletons

    listView = @getListView()

    computeController.on 'RenderStacks', @bound 'loadItems'

    listView.on 'ItemAction', ({ action, item, options }) =>

      switch action
        when 'StackReinitRequested' then @handleStackReinitRequest  item
        when 'StackDeleteRequested' then @handleStackDeleteRequest  item
        when 'NewMachineRequest'    then @handleNewMachineRequest   item


  handleNewMachineRequest: (provider) ->

    ComputeHelpers.handleNewMachineRequest { provider }, (machineCreated) =>
      @getListView().emit 'ModalDestroyRequested', not machineCreated


  handleStackDeleteRequest: (item) ->

    { computeController, router } = kd.singletons
    listView = @getListView()

    stack = item.getData()
    computeController.destroyStack stack, (err) ->
      return  if showError err

      new kd.NotificationView { title : 'Stack deleted' }

      computeController.reset yes, -> router.handleRoute '/IDE'


  handleStackReinitRequest: (item) ->

    { computeController } = kd.singletons

    stack = item.getData()
    computeController.reinitStack stack, ->
      item.reinitButton.hideLoader()

    computeController.once 'RenderStacks', =>
      @getListView().emit 'ModalDestroyRequested', yes, yes


  addListItems: (stacks) ->

    stacks = sortStacks stacks

    super stacks

    return  if stacks.length is 1

    @getView().setClass 'multi-stack'

    @getItemsOrdered().forEach (view) =>
      view.header.show()

      if stackId = @getOption 'selected'
        unless stackId is view.getData().getId()
          view.setClass 'collapsed'
