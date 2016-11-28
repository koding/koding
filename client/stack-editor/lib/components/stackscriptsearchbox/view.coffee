kd = require 'kd'
React = require 'app/react'
ScrollableContent = require 'app/components/scroller'


module.exports = class StackScriptSearchBoxView extends React.Component

  renderResultList: ->

    i = 0
    @props.scripts.map (script) =>
      <List item={script} key={i++} callback={@props.onClick.bind this, script} />


  renderResults: ->

    return  unless @props.scripts.length
    return  if @props.close

    <ScrollableContent className='stack-script-search-scroll' ref='resultbox'>
      {@renderResultList()}
    </ScrollableContent>


  isIconVisible: ->

    icon = if @props.loading then 'loading-icon' else 'close-icon'
    return (!(@props.query or @props.scripts.length)) or (@props.close and icon is 'close-icon')


  renderIcon: ->

    return  if @isIconVisible()

    icon = if @props.loading then 'loading-icon' else 'close-icon'
    <span className={icon} onClick={@props.onIconClick}></span>


  renderLink: ->
    className = "HomeAppView--button secondary stack-script-search-link"
    className = kd.utils.curry className, 'shift'  unless @isIconVisible()
    <a
      className={className}
      href='http://www.koding.com/docs/home'
      style={ color: '#67a2ee' }>
      GO TO DOCS
    </a>


  render: ->

    <div className='StackEditor-SearchWrapper'>
      <SearchInputBox
        value={@props.query}
        onChangeCallback={@props.onChange}
        onKeyUp={@props.onKeyUp}
        active={not @isIconVisible()}
        onFocusCallback={@props.onFocus} />
      {@renderLink()}
      {@renderIcon()}
      {@renderResults()}
    </div>


SearchInputBox = ({ value, onChangeCallback, onFocusCallback, onKeyUp, active }) ->

  <input
    type='text'
    className="kdinput text searchStackInput#{if active then ' active' else ''}"
    placeholder='Search Docs, AWS, S3, Azure, GCP...'
    value={value}
    onChange={onChangeCallback}
    onKeyUp={onKeyUp}
    onClick={onFocusCallback}
    onFocus={onFocusCallback} />


List = ({ item, callback }) ->

  <div className='item-wrapper' onClick={callback}>
    <div className='item'>
      <div className='title'> {item.title} </div>
      <div className='description'> {item.description} </div>
    </div>
  </div>
