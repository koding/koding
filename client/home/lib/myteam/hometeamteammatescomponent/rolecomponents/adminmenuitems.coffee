kd              = require 'kd'
React           = require 'kd-react'
TeamFlux        = require 'app/flux/teams'
KDReactorMixin  = require 'app/flux/base/reactormixin'

MakeMember = require './makemember'
MakeOwner  = require './makeowner'
MakeModerator = require './makemoderator'
DisableUser = require './disableuser'



module.exports = class AdminMenuItems extends React.Component

  constructor: (props) ->

    super props


  render: ->

    <div>
      <MakeOwner member={@props.member}/>
      <MakeMember member={@props.member}/>
      <MakeModerator member={@props.member}/>
      <DisableUser member={@props.member}/>
    </div>

