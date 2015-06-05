kd = require 'kd'

module.exports = ShowcaseRouteHandlers =

  # /Showcase
  handleShowcaseIndex: ->

    openShowcase (showcase) ->

  # /Showcase/:collection/:component
  handleShowComponent: ({ params: { collection, component } })->

    openShowcase (showcase) ->

      showcase.showCollectionComponent collection, component


openShowcase = (callback) ->
  {appManager, mainController} = kd.singletons
  mainController.ready -> appManager.open 'Showcase', callback
