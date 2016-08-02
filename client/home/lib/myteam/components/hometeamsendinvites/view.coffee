kd = require 'kd'
React = require 'kd-react'
List = require 'app/components/list'
CheckBox = require 'app/components/common/checkbox'


module.exports = class HomeTeamSendInvitesView extends React.Component

  onClickUploadCsv: -> @input.click()

  numberOfSections: -> 1


  numberOfRowsInSection: ->

    @props.inputValues?.size or 0


  renderSectionHeaderAtIndex: -> null


  renderRowAtIndex: (sectionIndex, rowIndex) ->

    inviteInput = @props.inputValues.toList().get(rowIndex)
    checked = inviteInput.get('canEdit')

    { focusFirstEmail } = @props

    userEmailClassName = 'kdinput text user-email'
    userEmailClassName = 'kdinput text user-email focus-first-email'  if focusFirstEmail


    <div className='kdview invite-inputs'>
      <input type='text' className={userEmailClassName} placeholder='mail@example.com' value={inviteInput.get 'email'} onChange={@props.onInputChange.bind(this, rowIndex, 'email')} />
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
          title='SEND INVITES'
          className={'custom-link-view HomeAppView--button primary fr'}
          callback={@props.onSendInvites}/>
        <GenericButton
          title='UPLOAD CSV'
          className={'custom-link-view HomeAppView--button ft'}
          callback={@bound 'onClickUploadCsv'} />
        <input ref={(input) => @input = input} multiple accept='.csv' className='kdinput file uploadcsv' type='file' onChange={@props.onUploadCsv} />
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


GenericButton = ({ className, title, callback }) ->

  <a className={className} href='#' onClick={callback}>
    <span className='title'>{title}</span>
  </a>
