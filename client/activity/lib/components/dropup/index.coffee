$            = require 'jquery'
kd           = require 'kd'
React        = require 'kd-react'
classnames   = require 'classnames'
ActivityFlux = require 'activity/flux'

module.exports = class Dropup extends React.Component

  @defaultProps =
    visible   : no
    className : ''


  componentDidMount: ->

    document.addEventListener 'mousedown', @bound 'handleMouseClick'


  componentWillUnmount: ->

    document.removeEventListener 'mousedown', @bound 'handleMouseClick'


  componentDidUpdate: ->

    return  unless @props.visible

    element = $ @getMainElement()
    element.css top : -element.outerHeight()


  getMainElement: -> React.findDOMNode @refs.dropup


  handleMouseClick: (event) ->

    return  unless @props.visible

    { target } = event
    element    = React.findDOMNode this
    innerClick = $.contains element, target

    @props.onOuterClick?()  unless innerClick


  getClassName: ->

    { className, visible } = @props

    classes =
      'Dropup-container' : yes
      'hidden'           : not visible
    classes[className]   = yes  if className

    return classnames classes


  render: ->

    className = @getClassName()

    <div className={className}>
      <div className="Dropup" ref="dropup">
        {@props.children}
      </div>
    </div>

