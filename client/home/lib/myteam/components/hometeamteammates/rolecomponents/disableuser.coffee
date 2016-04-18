kd              = require 'kd'
React           = require 'kd-react'
TeamFlux        = require 'app/flux/teams'
KDReactorMixin  = require 'app/flux/base/reactormixin'


module.exports = class DisableUser extends React.Component

  changeRole: ->

    TeamFlux.actions.handleKickMember @props.account


  render: ->

    <button type="button" className="kdbutton solid compact outline red w-loader" onClick={@bound 'changeRole'}>
      <span className="icon hidden"></span>
      <span className="button-title">DISABLE USER</span>
    </button>

