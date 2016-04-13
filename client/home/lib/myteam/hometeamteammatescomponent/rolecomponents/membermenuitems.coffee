kd              = require 'kd'
React           = require 'kd-react'
TeamFlux        = require 'app/flux/teams'
KDReactorMixin  = require 'app/flux/base/reactormixin'

MakeAdmin = require './makeadmin'
MakeOwner  = require './makeowner'
MakeModerator = require './makemoderator'
DisableUser = require './disableuser'


module.exports = class MemberMenuItems extends React.Component

  constructor: (props) ->

    super props


  render: ->

    <div>
      <MakeOwner member={@props.member}/>
      <MakeAdmin member={@props.member}/>
      <MakeModerator member={@props.member}/>
      <DisableUser member={@props.member}/>
    </div>

