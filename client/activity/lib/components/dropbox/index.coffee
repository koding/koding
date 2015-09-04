$            = require 'jquery'
kd           = require 'kd'
React        = require 'kd-react'
classnames   = require 'classnames'
ActivityFlux = require 'activity/flux'

module.exports = class Dropbox extends React.Component

  @defaultProps =
    visible   : no
    className : ''
    direction : 'down'


  componentDidMount: ->

    document.addEventListener 'mousedown', @bound 'handleMouseClick'


  componentWillUnmount: ->

    document.removeEventListener 'mousedown', @bound 'handleMouseClick'


  componentDidUpdate: ->

    return  unless @props.visible
    return  unless @props.direction is 'up'

    element = $ @getMainElement()
    element.css top : -element.outerHeight()


  getMainElement: -> React.findDOMNode @refs.dropbox


  handleMouseClick: (event) ->

    return  unless @props.visible

    { target } = event
    element    = React.findDOMNode this
    innerClick = $.contains element, target

    @props.onOuterClick?()  unless innerClick


  getClassName: ->

    { className, visible } = @props

    classes =
      'Dropbox-container' : yes
      'hidden'            : not visible
    classes[className]   = yes  if className

    return classnames classes


  render: ->

    className = @getClassName()

    <div className={className}>
      <div className="Dropbox" ref="dropbox">
        {@props.children}
      </div>
    </div>

