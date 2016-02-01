kd       = require 'kd'
React    = require 'kd-react'
ReactDOM = require 'react-dom'

module.exports = class DropboxHeader extends React.Component

  @propTypes =
    title    : React.PropTypes.string
    subtitle : React.PropTypes.string

  @defaultProps =
    title    : ''
    subtitle : ''


  renderSubtitle: ->

    { subtitle } = @props
    return  unless subtitle

    <span className="Dropbox-subtitle">{ subtitle }</span>


  render: ->

    { title } = @props
    return null  unless title

    <div className='Dropbox-header'>
      { title }
      { @renderSubtitle() }
    </div>
