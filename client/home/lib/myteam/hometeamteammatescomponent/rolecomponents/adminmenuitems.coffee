kd              = require 'kd'
React           = require 'kd-react'
TeamFlux        = require 'app/flux/teams'
KDReactorMixin  = require 'app/flux/base/reactormixin'

MakeMember = require './makemember'
MakeOwner  = require './makeowner'
MakeModerator = require './makemoderator'
DisableUser = require './disableuser'



module.exports = class AdminMenuItems extends React.Component

  render: ->

    <div>
      <MakeOwner account={@props.account}/>
      <MakeMember account={@props.account}/>
      <MakeModerator account={@props.account}/>
      <DisableUser account={@props.account}/>
    </div>

