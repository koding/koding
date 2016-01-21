kd = require 'kd'

showError  = require 'app/util/showError'
sortStacks = require 'app/util/sortEnvironmentStacks'


module.exports = class EnvironmentListController extends kd.ListViewController

  constructor: (options = {}, data) ->

    super options, data

    @loadItems()


  loadItems: (stacks) ->

    @removeAllItems()

    if stacks
      @addListItems stacks
      return

    @showLazyLoader()

    { computeController } = kd.singletons

    computeController.fetchStacks (err, stacks) =>

      @hideLazyLoader()

      return if showError err, \
        KodingError : "Failed to fetch stacks, please try again later."

      @addListItems stacks


  addListItems: (stacks) ->

    stacks = sortStacks stacks

    @instantiateListItems stacks

    return  if stacks.length is 1

    @getView().setClass 'multi-stack'

    @getItemsOrdered().forEach (view) =>
      view.header.show()

      if stackId = @getOption 'selected'
        unless stackId is view.getData().getId()
          view.setClass 'collapsed'

