kd = require 'kd'
React = require 'kd-react'
moment = require 'moment'


module.exports = class DateMarker extends React.Component

  @defaultProps = { date: null }

  renderDate: ->

    return null  unless @props.date

    dateString = moment(@props.date).calendar null,
      sameDay  : '[Today]'
      nextDay  : '[Tomorrow]'
      nextWeek : 'dddd'
      lastDay  : '[Yesterday]'
      lastWeek : '[Last] dddd'

    return \
      <div className="DateMarker-content">
        {dateString}
      </div>


  render: ->
    <div className={kd.utils.curry "DateMarker", @props.className}>
      {@renderDate()}
    </div>


