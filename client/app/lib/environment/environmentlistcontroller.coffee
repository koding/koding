kd        = require 'kd'
showError = require 'app/util/showError'


module.exports = class EnvironmentListController extends kd.ListViewController

  constructor: (options = {}, data) ->

    super options, data

    @loadItems()


  loadItems: ->

    @removeAllItems()
    @showLazyLoader()

    { computeController } = kd.singletons

    computeController.fetchStacks (err, stacks) =>

      @hideLazyLoader()

      return if showError err, \
        KodingError : "Failed to fetch stacks, try again later."

      @instantiateListItems stacks
