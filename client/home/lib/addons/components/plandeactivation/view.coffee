React = require 'app/react'
styles = require './styles.stylus'


module.exports = class PlanDeactivation extends React.Component

  handleDeactivationButtonClick: ->

    @props.onDeactivation()


  render: ->

    <div className={styles.deactivation}>
      <a href="#" onClick={@bound 'handleDeactivationButtonClick'}>DEACTIVATE {@props.target}</a>
    </div>
