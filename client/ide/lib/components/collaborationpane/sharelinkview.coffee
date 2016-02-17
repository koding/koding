kd                      = require 'kd'
globals                 = require 'globals'
React                   = require 'kd-react'
Link                    = require 'app/components/common/link'
CollaborationShareModal = require './sharemodalview'



module.exports = class ShareLinkView extends React.Component

  @propTypes =
    url: React.PropTypes.string.isRequired


  onLinkClick: ->

    modal = new CollaborationShareModal {url: @props.url}


  render: ->
    <div className="ShareLink">
      <button className="Button Button--primary" onClick={@bound 'onLinkClick'}>Invite</button>
    </div>


