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

    if stacks.length > 1
      view.title.show()  for view in @getItemsOrdered()
      @getView().setClass 'multi-stack'
