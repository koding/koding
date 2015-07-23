kd    = require 'kd'
React = require 'kd-react'

module.exports = class ButtonWithMenu extends React.Component
  constructor: (props) ->
    @defaultProps = { items: [], showMenuForMouseAction: no}
    @state = { showSettingsMenu: props.showMenuForMouseAction or no }

  componentDidMount: ->
    @modalWrapper = document.createElement "div"
    #document.body.appendChild modalWrapper

  renderListMenu: ->
    @props.items.map (item) ->
      <li onClick={item.onClick} key={item.key} >{item.title}</li>


  onButtonClick: (event) ->
    event.preventDefault()
    event.stopPropagation()
    @setState showSettingsMenu: yes
    @props.showMenuForMouseAction = yes


  render: ->
    settingsMenuListClassName = if @state.showSettingsMenu and @props.showMenuForMouseAction then 'SettingsMenuList' else 'SettingsMenuList hidden'
    <div className="SettingsMenuWrapper">
      <button type="button" onClick={@bound 'onButtonClick'} ></button>
      <ul className={settingsMenuListClassName} ref="SettingsMenuList">
        {@renderListMenu()}
      </ul>
    </div>




