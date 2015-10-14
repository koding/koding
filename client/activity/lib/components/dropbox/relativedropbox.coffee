$          = require 'jquery'
kd         = require 'kd'
React      = require 'kd-react'
classnames = require 'classnames'
Dropbox    = require './dropboxbody'

module.exports = class RelativeDropbox extends React.Component

  componentDidUpdate: ->

    return  unless @props.visible
    return  unless @props.direction is 'up'

    dropbox = $ React.findDOMNode @refs.dropbox
    dropbox.css top : -element.outerHeight()


  getContentElement: -> @refs.dropbox.getContentElement()


  render: ->

    { visible } = @props

    className = classnames
      'Dropbox-container' : yes
      'hidden'            : not visible

    <div className={className}>
      <Dropbox {...@props} ref='dropbox'>
        { @props.children }
      </Dropbox>
    </div>

