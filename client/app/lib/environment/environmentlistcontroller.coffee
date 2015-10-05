kd        = require 'kd'
showError = require 'app/util/showError'


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

    @instantiateListItems stacks

    return  if stacks.length is 1

    @getView().setClass 'multi-stack'

    @getItemsOrdered().forEach (view) =>
      view.header.show()

      if stack = @getOption 'selected'
        unless stack.getId() is view.getData().getId()
          view.setClass 'collapsed'
