React = require 'kd-react'


module.exports = class MigrationFinished extends React.Component

  render: ->

    <div className="MigrationFinished">
      <div className="background"></div>
      <h1>Success!</h1>
      <h2>Your VMs have been imported.</h2>
    </div>


