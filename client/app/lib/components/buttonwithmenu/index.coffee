kd     = require 'kd'
React  = require 'kd-react'
$      = require 'jquery'
Portal   = require('react-portal').default

module.exports = class ButtonWithMenu extends React.Component

  WINDOW_OFFSET = 100

  @defaultProps =
    items: []
    isMenuOpen: no
    listClass:''

  constructor: (props) ->

    super props

    @state = { isMenuOpen: @props.isMenuOpen }


  renderListMenu: ->

    onClick = (item) => (event) =>
      item.onClick event
      @onMenuClose()

    @props.items.map (item) ->
      <li onClick={onClick item} key={item.key}>{item.title}</li>


  listDidMount: (_list) ->

    button = React.findDOMNode @refs.button
    list = React.findDOMNode _list
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
      <Portal isOpened={@state.isMenuOpen} closeOnOutsideClick={yes} closeOnEsc={yes} onClose={@bound 'onMenuClose'}>
        <ul ref={@bound 'listDidMount'} className={kd.utils.curry "ButtonWithMenuItemsList", @props.listClass}>
          {@renderListMenu()}
        </ul>
      </Portal>
    </div>




