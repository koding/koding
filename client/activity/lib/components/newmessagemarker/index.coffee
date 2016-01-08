kd = require 'kd'
React = require 'kd-react'


module.exports = class NewMessageMarker extends React.Component

  render: ->
    <div className="NewMessageMarker">
      <div className="NewMessageMarker-content">
        new messages
      </div>
    </div>
