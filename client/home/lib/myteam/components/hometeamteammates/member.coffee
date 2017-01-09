kd    = require 'kd'
React = require 'app/react'
ProfilePicture = require 'app/components/profile/profilepicture'
capitalizeFirstLetter = require 'app/util/capitalizefirstletter'
ButtonWithMenu = require 'app/components/buttonwithmenu'
whoami = require 'app/util/whoami'

module.exports = class Member extends React.Component

  constructor: (props) ->

    super props


  getMenuItems: (role) ->

    items = []

    if role is 'owner'
      items.push { title: 'Make member', key: 'makemember', onClick: @props.handleRoleChange.bind(this, @props.member, 'member') }
    else if role is 'admin'
      items.push { title: 'Make owner', key: 'mameowner', onClick: @props.handleRoleChange.bind(this, @props.member, 'owner') }
      items.push { title: 'Make member', key: 'makemember', onClick: @props.handleRoleChange.bind(this, @props.member, 'member') }  if @props.admins.size
      items.push { title: 'Disable user', key: 'disableuser', onClick: @props.handleRoleChange.bind(this, @props.member, 'kick') }  if @props.admins.size
    else if role is 'Invitation Sent'
      items.push { title: 'Resend Invitation', key: 'resend', onClick: @props.handleInvitation.bind(this, @props.member, 'resend') }
      items.push { title: 'Revoke Invitation', key: 'revoke', onClick: @props.handleInvitation.bind(this, @props.member, 'revoke') }
    else if role is 'disabled'
      items.push { title: 'Remove Permanently', key: 'delete', onClick: @props.handleDisabledUser.bind(this, @props.member, 'delete') }
      items.push { title: 'Enable User', key: 'enable', onClick: @props.handleDisabledUser.bind(this, @props.member, 'enable') }
    else
      items.push { title: 'Make owner', key: 'makemember', onClick: @props.handleRoleChange.bind(this, @props.member, 'owner') }
      items.push { title: 'Make admin', key: 'makeadmin', onClick: @props.handleRoleChange.bind(this, @props.member, 'admin') }
      items.push { title: 'Disable user', key: 'disableuser', onClick: @props.handleRoleChange.bind(this, @props.member, 'kick') }

    return items


  getData: ->

    nickname = @props.member.getIn ['profile', 'nickname']
    email = @props.member.getIn ['profile', 'email']
    role = @props.member.get 'role'
    firstName = @props.member.getIn ['profile', 'firstName']
    lastName = @props.member.getIn ['profile', 'lastName']
    fullName = "#{firstName} #{lastName}"

    if @props.member.get('status') is 'pending'
      role = 'Invitation Sent'
      firstName = @props.member.get('firstName') or ''
      lastName = @props.member.get('lastName') or ''
      fullName = @props.member.get 'email'
      email = "#{firstName} #{lastName}"
      nickname = ''

    return { nickname, email, role, firstName, lastName, fullName }


  render: ->

    canEdit = kd.singletons.groupsController.canEditGroup()
    { nickname, email, role, firstName, lastName, fullName } = @getData()

    <div>
      <AvatarView member={@props.member} role={role}/>
      <div className='details'>
        <div className='fullname'>{fullName}</div>
        <div className='metaData'>
          <Email email={email} />
          <NickName nickname={nickname}/>
        </div>
      </div>
      <MemberRoleWithDropDownMenu
        role={role}
        items={@getMenuItems role}
        admins={@props.admins}
        canEdit={canEdit}
        member={@props.member} />
    </div>


MemberRoleWithDropDownMenu = ({ canEdit, role, items, admins, member }) ->

  showButtonWithMenu = role is 'owner' and admins.size is 0
  unless canEdit and not showButtonWithMenu
    <div className='dropdown'>
      <MemberRole role={role} canEdit={canEdit}  />
      {<ButtonWithMenu menuClassName='menu-class' items={items} />  if member.get('inviterId') is whoami()._id}
    </div>
  else
    <div className='dropdown'>
      <MemberRole role={role} canEdit={canEdit} showPointer={yes} />
      <ButtonWithMenu menuClassName='menu-class' items={items} />
    </div>


Badge = ({ role }) ->
  role = 'member'  unless role
  <div className={"badge #{role}"} title={role}></div>


NickName = ({ nickname }) ->

  if nickname.length
  then <span className='nickname'>@{nickname}</span>
  else <i></i>


Email = ({ email }) ->

  <span className='email-js email' title={email}>{email}</span>


AvatarView = ({ member, role }) ->

  unless member.get 'status'
    <div className='avatarview' href='#'>
      <ProfilePicture account={member.toJS()} height={40} width={40} role={role} />
    </div>
  else
    <div className='avatarview default' href='#'>
    </div>


MemberRole = ({ role, canEdit, showPointer }) ->

  className = 'role'
  className = 'role showPointer'  if showPointer

  <div className={className}>{capitalizeFirstLetter role}</div>
