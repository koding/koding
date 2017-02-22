kd = require 'kd'
React = require 'app/react'
List = require 'app/components/list'
CheckBox = require 'app/components/common/checkbox'
isEmailValid = require 'app/util/isEmailValid'

module.exports = class HomeTeamSendInvitesView extends React.Component

  numberOfSections: -> 1


  numberOfRowsInSection: ->

    @props.inputValues?.size or 0


  renderSectionHeaderAtIndex: -> null


  renderRowAtIndex: (sectionIndex, rowIndex) ->

    inviteInput = @props.inputValues.toList().get(rowIndex)
    checked = inviteInput.get('canEdit')

    userEmailClassName = 'kdinput text user-email'

    <div className='kdview invite-inputs'>
      <input type='text' className={userEmailClassName} placeholder='mail@example.com' value={inviteInput.get 'email'} onChange={@props.onInputChange.bind(this, rowIndex, 'email')} onBlur={@props.onInputEmailBlur.bind(this, rowIndex)} />
      <input type='text' className='kdinput text firstname' placeholder='Optional' value={inviteInput.get 'firstName'} onChange={@props.onInputChange.bind(this, rowIndex, 'firstName')}/>
      <input type='text' className='kdinput text lastname' placeholder='Optional' value={inviteInput.get 'lastName'} onChange={@props.onInputChange.bind(this, rowIndex, 'lastName')}/>
      <CheckBoxOrEmpty
        canEdit={@props.canEdit}
        checked={checked}
        onChange={@props.onInputChange.bind(this, rowIndex, 'canEdit')}
        onClick={@props.onInputChange.bind(null, rowIndex, 'canEdit', { target: { value: not checked}})}/>
    </div>


  renderEmptySectionAtIndex: -> <div> No data found</div>


  render: ->
    count = _.sum this.props.inputValues.toList().toArray().map (inputRow) ->
       if isEmailValid inputRow.get 'email' then 1 else 0

    if count > 0
      buttonTitle = "Send #{count} Invite#{if count > 1 then 's' else ''}"
      buttonEnabled = yes
    else
      buttonTitle = "Send Invites"
      buttonEnabled = no

    <div>
      <InformationLabel canEdit={@props.canEdit} />
      <div className='input-wrapper'>
        <List
          numberOfSections={@bound 'numberOfSections'}
          numberOfRowsInSection={@bound 'numberOfRowsInSection'}
          renderSectionHeaderAtIndex={@bound 'renderSectionHeaderAtIndex'}
          renderRowAtIndex={@bound 'renderRowAtIndex'}
          renderEmptySectionAtIndex={@bound 'renderEmptySectionAtIndex'}
        />
      </div>
      <fieldset className='HomeAppView--ActionBar'>
        <GenericButton
          title=buttonTitle
          className={"custom-link-view HomeAppView--button primary #{unless buttonEnabled then 'inactive' else ''} fr"}
          spanClass='title GenericButton'
          callback={@props.onSendInvites}/>
        <GenericButton
          title='UPLOAD CSV'
          className={'custom-link-view HomeAppView--button ft'}
          spanClass='title'
          callback={@props.onUploadCSV} />
      </fieldset>
    </div>


CheckBoxOrEmpty = ({ canEdit, checked, onChange, onClick }) ->

  if canEdit
    <CheckBox checked={checked} onChange={onChange} onClick={onClick} />
  else
    <div></div>


InformationLabel = ({ canEdit }) ->

  lastname = 'Last Name'
  <div className='information'>
    <div className='invite-labels'>
      <label>Email</label>
      <label>First Name</label>
      <label>
        <span className='lastname'>Last Name</span>
        <AdminLabel canEdit={canEdit} />
      </label>
    </div>
  </div>


AdminLabel = ({ canEdit }) ->

  if canEdit
  then <span>Admin</span>
  else <span></span>


GenericButton = ({ className, spanClass, title, callback }) ->

  <a className={className} href='#' onClick={callback}>
    <span className={spanClass}>{title}</span>
  </a>
