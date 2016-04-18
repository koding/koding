kd              = require 'kd'
React           = require 'kd-react'
TeamFlux        = require 'app/flux/teams'
KDReactorMixin  = require 'app/flux/base/reactormixin'


module.exports = class MakeMember extends React.Component

  changeRole: ->

    TeamFlux.actions.handleRoleChange @props.account, 'member'


  render: ->

    <button type="button" className="kdbutton solid compact outline w-loader" onClick={@bound 'changeRole'}>
      <span className="icon hidden"></span>
      <span className="button-title">MAKE MEMBER</span>
    </button>

