kd = require 'kd'

connectCompute = require 'app/providers/connectcompute'
connectSidebar = require 'app/sidebar/connectsidebar'

calculateOwnedResources = require 'app/util/calculateOwnedResources'

Container = require './container'

module.exports = require './view'

computeConnector = connectCompute({
  storage: ['stacks', 'templates', 'machines']
})

sidebarConnector = connectSidebar({
  transformState: (sidebarState, props) ->

    { sidebar } = kd.singletons

    resources = calculateOwnedResources(props)
      .filter (resource) ->
        resource.stack and resource.template?.accessLevel is 'private'
      .map (resource) ->
        isVisible = if resource.stack
        then sidebar.isVisible 'stack', resource.stack.getId()
        else sidebar.isVisible 'draft', resource.template.getId()

        return Object.assign {}, resource, { isVisible }

    return { resources }
})

module.exports.Container = computeConnector sidebarConnector Container
