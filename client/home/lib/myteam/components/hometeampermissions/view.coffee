React  = require 'app/react'
Toggle = require 'app/components/common/toggle'

module.exports = class HomeTeamPermissionsView extends React.Component

  render: ->

    <div>
      <div className='Permissions-Line'>
        <ToggleButton
          checked={@props.canCreateStacks}
          callback={@props.onToggle.bind this, 'membersCanCreateStacks'} />
        <p className='primary'>
          <strong>Stack Creation</strong>
          Enable team members to create stacks
        </p>
      </div>
      <div className='Permissions-Line'>
        <ToggleButton
          checked={@props.seeTeamMembers}
          callback={(state) => @props.onToggle 'hideTeamMembers', not state} />
        <p className='primary'>
          <strong>See/Invite team members</strong>
          Enable team members to see/invite other members
        </p>
      </div>
    </div>


ToggleButton = ({ checked, callback }) ->

  checked ?= no

  <Toggle checked={checked} className='OnOffButton' callback={callback} />
