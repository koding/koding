kd = require 'kd'
React = require 'app/react'
ReactView = require 'app/react/reactview'

connectCompute = require 'app/providers/connectcompute'
connectSidebar = require 'app/sidebar/connectsidebar'

calculateOwnedResources = require 'app/util/calculateOwnedResources'
calculateSharedResources = require 'app/util/calculateSharedResources'

Container = require './container'

computeConnector = connectCompute({
  storage: ['stacks', 'templates', 'machines']
})

sidebarConnector = connectSidebar({
  transformState: (sidebarState, props) ->

    { sidebar } = kd.singletons

    ownedResources = calculateOwnedResources(props)
      .map (resource) ->
        isVisible = if resource.stack
        then sidebar.isVisible 'stack', resource.stack.getId()
        else sidebar.isVisible 'draft', resource.template.getId()

        return Object.assign {}, resource, { isVisible }
      .filter (resource) -> resource.isVisible

    sharedResources = calculateSharedResources props

    return Object.assign {}, props, { ownedResources, sharedResources }
})

ConnectedContainer = computeConnector sidebarConnector Container

module.exports = class SidebarView extends ReactView

  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry 'Sidebar-ReactView'

    super options, data


  renderReact: ->

    <ConnectedContainer />
