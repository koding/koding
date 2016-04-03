React = require 'kd-react'
MachinesListItem = require './listitem'
immutable = require 'immutable'


module.exports = class MachinesList extends React.Component

  @propTypes =
    stacks               : React.PropTypes.instanceOf(immutable.List).isRequired
    shouldRenderDetails  : React.PropTypes.bool
    shouldRenderSpecs    : React.PropTypes.bool
    shouldRenderPower    : React.PropTypes.bool
    shouldRenderAlwaysOn : React.PropTypes.bool
    shouldRenderSharing  : React.PropTypes.bool

  @defaultProps =
    shouldRenderDetails  : yes
    shouldRenderSpecs    : no
    shouldRenderPower    : yes
    shouldRenderAlwaysOn : no
    shouldRenderSharing  : no

  render: ->

    { ItemComponent, shouldRenderDetails, shouldRenderSpecs,
      shouldRenderPower, shouldRenderAlwaysOn, shouldRenderSharing } = @props

    children = @props.stacks.reduce (res, stack) ->
      machines = stack.get 'machines'
        .sort (a, b) -> a.get('label').localeCompare(b.get('label')) # Sorting from a to z
        .map (machine) ->
          <MachinesListItem
            key={machine.get '_id'} stack={stack} machine={machine}
            shouldRenderDetails={shouldRenderDetails}
            shouldRenderSpecs={shouldRenderSpecs}
            shouldRenderPower={shouldRenderPower}
            shouldRenderAlwaysOn={shouldRenderAlwaysOn}
            shouldRenderSharing={shouldRenderSharing} />

      return res.concat machines
    , []

    <div className='MachinesList'>{children}</div>


