kd    = require 'kd'
React = require 'kd-react'

module.exports = class ButtonWithMenu extends React.Component

  @defaultProps = { items: [], showMenuForMouseAction: no}

  constructor: (props) ->

    @state = { showSettingsMenu: props.showMenuForMouseAction or no }


  renderListMenu: ->

    @props.items.map (item) ->
      <li onClick={item.onClick} key={item.key}>{item.title}</li>


  onButtonClick: (event) ->

    kd.utils.stopDOMEvent event
    @setState showSettingsMenu: yes
    @props.showMenuForMouseAction = yes


  render: ->
    menuListClassName = if @state.showSettingsMenu and @props.showMenuForMouseAction then 'ButtonWithMenuItemsList' else 'ButtonWithMenuItemsList hidden'
    <div className="SettingsMenuWrapper">
      <button type="button" onClick={@bound 'onButtonClick'}></button>
      <ul className={menuListClassName}>
        {@renderListMenu()}
      </ul>
    </div>




