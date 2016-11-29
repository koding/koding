kd = require 'kd'
React = require 'app/react'
ReactView = require 'app/react/reactview'

Modal = require 'lab/Modal'

module.exports = class FailuresModal extends React.Component

  constructor: (props) ->

    super props

    isOpen = {}
    for file in props.files
      isOpen[file] = no

    mustGotoRainforest = []
    for file in props.files
      suites = props.store[file].filter (suite) -> suite.status is 'Cannot be Automated'
      mustGotoRainforest.push file  if suites.length
    @state = { isOpen, mustGotoRainforest }


  fileNameOnClick: (fileName) ->

    @state.isOpen[fileName] = not @state.isOpen[fileName]
    @setState @state.isOpen

  render: ->
    return <span />  unless @props.files.length

    suiteResults = []
    [0..@props.files.length-1].forEach (i) =>
      fileName = @props.files[i]
      mustGotoRainforest = fileName in @state.mustGotoRainforest

      suiteResults.push <SuiteResult
        key={i}
        fileName={fileName}
        suites={@props.store[fileName]}
        isOpen={@state.isOpen[fileName]}
        mustGotoRainforest={mustGotoRainforest}
        callback={@fileNameOnClick.bind(this, fileName)} />

    <div className='failures-modal'>
      {suiteResults}
    </div>


SuiteResult = ({ suites, fileName, isOpen, mustGotoRainforest, callback }) ->

  return <span />  unless suites.length

  suiteItems = []
  suites.forEach (suite, i) ->
    { status, title } = suite
    suiteItems.push <SuiteResultItem key={i} title={title} status={status} />


  wrapperClassName = 'file-name-wrapper'
  wrapperClassName = 'file-name-wrapper active'  if isOpen

  fileNameClassName = 'file-name '
  fileNameClassName = 'file-name rainforest'  if mustGotoRainforest

  <div className='suite'>
    <div className={wrapperClassName}>
      <div className={fileNameClassName} onClick={callback}>{fileName}</div>
    </div>
    <Header isOpen={isOpen} />
    {if isOpen then suiteItems else <span />}
  </div>


SuiteResultItem = ({ title, status }) ->
  statusClassName = unless status is 'Cannot be Automated' or status is 'Not Implemented' then 'error'
  else if status is 'Cannot be Automated' then 'hti'
  else 'ni'

  <div className='suite-info-wrapper'>
    <div className='title'>{title}</div>
    <div className='status'>
      <span className={statusClassName}>{status}</span>
    </div>
  </div>


Header = ({ isOpen }) ->

  return <span />  unless isOpen

  <div className='header'>
    <div className='suite-name'>Suite Name</div>
    <div className='status'>Status</div>
  </div>
