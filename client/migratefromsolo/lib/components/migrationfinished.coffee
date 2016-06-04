React = require 'kd-react'


module.exports = class MigrationFinished extends React.Component

  render: ->

    <div className="MigrationFinished">
      <div className="MigrationFinished-message">
        <h1>Success!</h1>
        <h2>Your solo machines are migrated.</h2>
      </div>
      <button className="GenericButton" onClick={@props.onClick}>Go to stacks</button>
    </div>


