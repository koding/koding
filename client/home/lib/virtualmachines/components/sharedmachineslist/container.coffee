kd = require 'kd'
React = require 'app/react'
View = require './view'

connectCompute = require 'app/providers/connectcompute'

computeConnector = connectCompute({
  storage: ['machines']
})

module.exports = computeConnector class SharedMachinesListContainer extends React.Component

  render: ->

    machines = @props.machines.filter (m) -> m.getType() is 'shared'

    <View machines={machines} />
