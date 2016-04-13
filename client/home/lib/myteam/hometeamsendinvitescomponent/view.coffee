kd               = require 'kd'
React            = require 'kd-react'
List             = require 'app/components/list'


module.exports = class HomeTeamSendInvitesView extends React.Component

  numberOfSections: -> 1


  numberOfRowsInSection: ->

    @props.inviteInputs?.size or 0


  renderSectionHeaderAtIndex: -> null


  renderRowAtIndex: (sectionIndex, rowIndex) ->

    inviteInput = @props.inviteInputs.get(rowIndex)
    checked = inviteInput.get('role') is 'admin'

    <div className='kdview invite-inputs'>
      <input type='text' className='kdinput text user-email' placeholder='mail@example.com' value={inviteInput.get 'email'} onChange={@props.onInputChange.bind(this, rowIndex, 'email')} />
      <input type='text' className='kdinput text firstname' placeholder='Optional' value={inviteInput.get 'firstname'} onChange={@props.onInputChange.bind(this, rowIndex, 'fistname')}/>
      <input type='text' className='kdinput text lastname' placeholder='Optional' value={inviteInput.get 'lastname'} onChange={@props.onInputChange.bind(this, rowIndex, 'lastname')}/>
      <div className='kdcustomcheckbox' >
        <input type='checkbox' className='kdinput checkbox' checked={checked} onChange={@props.onInputChange.bind(this, rowIndex, 'role')}/>
        <label onClick={@props.onInputChange.bind(null, rowIndex, 'role', { target: { value: not checked}})}></label>
      </div>
    </div>


  renderEmptySectionAtIndex: -> <div> No data found</div>


  renderSendInvites: ->

    <a className='custom-link-view HomeAppView--button primary fr' href='#' onClick={@props.onSendInvites}>
      <span className='title'>SEND INVITES</span>
    </a>


  renderUploadCsv: ->

    <a className='custom-link-view HomeAppView--button ft' href='#' onClick={@props.onUploadCsv}>
      <span className='title'>UPLOAD CSV</span>
    </a>


  renderInformation: ->
    lastname = 'Last Name'
    <div className='information'>
      <div className='invite-labels'>
        <label>Email</label>
        <label>First Name</label>
        <label>Last Name<span>Admin</span>
        </label>
      </div>
    </div>


  render: ->

    <div>
      {@renderInformation()}
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
        {@renderSendInvites()}
        {@renderUploadCsv()}
      </fieldset>
    </div>