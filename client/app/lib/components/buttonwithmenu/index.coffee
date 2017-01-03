kd       = require 'kd'
React    = require 'app/react'
ReactDOM = require 'react-dom'
Portal   = require 'react-portal'
$        = require 'jquery'

require './styl/buttonwithmenu.styl'


module.exports = class ButtonWithMenu extends React.Component

  WINDOW_OFFSET = 100

  @defaultProps =
    items: []
    listClass:''
    menuClassName:''


  constructor: (props) ->

    super props

    @state = { isMenuOpen : null }


  renderListMenu: ->

    onClick = (item) => (event) =>
      item.onClick event
      @setState { isMenuOpen: false }

    @props.items.map (item) ->
      <li onClick={onClick item} key={item.key}>{item.title}</li>


  listDidMount: (_list) ->

    button = ReactDOM.findDOMNode @refs.button
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


  render: ->

    button = <button ref='button'></button>

    <div className="ButtonWithMenuWrapper">
      <Portal openByClickOn={button} closeOnOutsideClick closeOnEsc isOpened={@state.isMenuOpen}>
        <div className={@props.menuClassName}>
          <ul ref={@bound 'listDidMount'} className={kd.utils.curry "ButtonWithMenuItemsList", @props.listClass}>
            {@renderListMenu()}
          </ul>
        </div>
      </Portal>
    </div>
