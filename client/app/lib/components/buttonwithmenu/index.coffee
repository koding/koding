kd       = require 'kd'
React    = require 'kd-react'
ReactDOM = require 'react-dom'
Portal   = require('react-portal').default
$        = require 'jquery'

require './styl/buttonwithmenu.styl'


module.exports = class ButtonWithMenu extends React.Component

  WINDOW_OFFSET = 100

  @defaultProps =
    items: []
    isMenuOpen: no
    listClass:''
    menuClassName:''

  constructor: (props) ->

    super props

    @state = { isMenuOpen: @props.isMenuOpen }


  componentWillReceiveProps: (nextProps) ->

    { isMenuOpen } = nextProps

    @setState { isMenuOpen }


  renderListMenu: ->

    onClick = (item) => (event) =>
      item.onClick event
      @onMenuClose()

    @props.items.map (item) ->
      <li onClick={onClick item} key={item.key}>{item.title}</li>


  listDidMount: (_list) ->

    button = ReactDOM.findDOMNode @refs.button
    return @setState isMenuOpen: no  unless button
    list = ReactDOM.findDOMNode _list
    buttonRect = button.getBoundingClientRect()

    mainHeight = $(window).height()
    mainScroll = $(window).scrollTop()
    menuHeight = $(list).height()
    menuWidth  = $(list).width()

    menuTop = if buttonRect.top + menuHeight + WINDOW_OFFSET > mainHeight + mainScroll
    then buttonRect.top - menuHeight
    else buttonRect.top

    $(list).css top: menuTop, left: buttonRect.left + buttonRect.width - menuWidth


  onMenuClose: ->

    @setState isMenuOpen: no
    @props.onMenuClose?()


  onButtonClick: (event) ->

    kd.utils.stopDOMEvent event
    @setState isMenuOpen: yes
    @props.onMenuOpen?()


  render: ->

    <div className="ButtonWithMenuWrapper">
      <button ref="button" onClick={@bound 'onButtonClick'}></button>
      <Portal className={@props.menuClassName} isOpened={@state.isMenuOpen} closeOnOutsideClick={yes} closeOnEsc={yes} onClose={@bound 'onMenuClose'}>
        <ul ref={@bound 'listDidMount'} className={kd.utils.curry "ButtonWithMenuItemsList", @props.listClass}>
          {@renderListMenu()}
        </ul>
      </Portal>
    </div>
