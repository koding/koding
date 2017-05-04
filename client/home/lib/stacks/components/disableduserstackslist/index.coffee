kd = require 'kd'

connectCompute = require 'app/providers/connectcompute'
connectSidebar = require 'app/sidebar/connectsidebar'

calculateOwnedResources = require 'app/util/calculateOwnedResources'

Container = require './container'

module.exports = require './view'

computeConnector = connectCompute({
  storage: ['stacks', 'templates', 'machines']
  transformState: ({ stacks, templates }) -> {
    resources: calculateOwnedResources({ stacks, templates })
      .filter (res) -> res.stack?.getOldOwner()
  }
})

module.exports.Container = computeConnector Container
