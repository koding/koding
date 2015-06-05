kd = require 'kd'
AppController = require 'app/appcontroller'
ShowcaseAppView = require './appview'

ComponentRegistry = require './registry'

require('./routehandler')()

module.exports = class ShowcaseAppController extends AppController

  @options = { name: 'Showcase' }

  constructor: (options, data) ->

    options.appInfo = { title: 'Showcase' }
    options.view = new ShowcaseAppView

    super options, data


  ###*
   * Get given record from registry and pass it to view so that it can be
   * rendered on the page.
   *
   * @param {string} collection
   * @param {string} componentName
  ###
  showCollectionComponent: (collection, componentName) ->

    # allow components to be reached case-insensitively.
    collection = collection.toLowerCase()
    componentName = componentName.toLowerCase()

    return  unless record = ComponentRegistry.get collection, componentName

    { type, component, props } = record

    switch type
      when 'react'
        @getView().showReactComponent component, props
      when 'kd'
        @getView().showKDView component, props


