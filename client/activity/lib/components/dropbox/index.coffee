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

    element = $ React.findDOMNode @refs.dropbox
    element.css top : -element.outerHeight()


  getContentElement: -> React.findDOMNode @refs.content


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


  renderSubtitle: ->

    { subtitle } = @props
    return  unless subtitle

    <span className="Dropbox-subtitle">{ subtitle }</span>


  renderHeader: ->

    { title } = @props
    return unless title

    <div className='Dropbox-header'>
      { title }
      { @renderSubtitle() }
    </div>


  render: ->

    className = @getClassName()

    <div className={className}>
      <div className='Dropbox' ref='dropbox'>
        { @renderHeader() }
        <div className='Dropbox-scrollable' ref='content'>
          <div className='Dropbox-content'>
            { @props.children }
          </div>
        </div>
      </div>
    </div>

