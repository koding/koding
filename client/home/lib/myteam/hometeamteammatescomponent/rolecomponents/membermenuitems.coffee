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
      <MakeOwner account={@props.account}/>
      <MakeAdmin account={@props.account}/>
      <MakeModerator account={@props.account}/>
      <DisableUser account={@props.account}/>
    </div>

