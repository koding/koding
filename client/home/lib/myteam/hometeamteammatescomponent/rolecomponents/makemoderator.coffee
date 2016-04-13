kd              = require 'kd'
React           = require 'kd-react'
TeamFlux        = require 'app/flux/teams'
KDReactorMixin  = require 'app/flux/base/reactormixin'


module.exports = class MakeModerator extends React.Component

  constructor: (props) ->

    super props


  changeRole: () ->
    console.log 'MODERATOR'


  render: ->

    <button type="button" className="kdbutton solid compact outline w-loader" onClick={@bound 'changeRole'}>
      <span className="icon hidden"></span>
      <span className="button-title">MAKE MODERATOR</span>
    </button>

