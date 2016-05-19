kd    = require 'kd'
React = require 'kd-react'
ProfilePicture = require 'app/components/profile/profilepicture'
capitalizeFirstLetter = require 'app/util/capitalizefirstletter'
ButtonWithMenu = require 'app/components/buttonwithmenu'


module.exports = class Member extends React.Component

  constructor: (props) ->

    super props

    @state =
      isMenuOpen: no


  onClickMemberRole: (role, event) ->

    kd.utils.stopDOMEvent event
    @setState { isMenuOpen: yes }


  componentWillReceiveProps: (nextProps) ->

    { isMenuOpen } = nextProps

    @setState { isMenuOpen }


  getMenuItems: (role) ->

    items = []

    if role is 'owner'
      items.push { title: 'Make member', key: 'makemember', onClick: @props.handleRoleChange.bind(this, @props.member, 'member') }
    else if role is 'admin'
      items.push { title: 'Make owner', key: 'mameowner', onClick: @props.handleRoleChange.bind(this, @props.member, 'owner') }
      items.push { title: 'Make member', key: 'makemember', onClick: @props.handleRoleChange.bind(this, @props.member, 'member') }
      items.push { title: 'Disable user', key: 'disableuser', onClick: @props.handleRoleChange.bind(this, @props.member, 'kick') }
    else if role is 'Invitation Sent'
      items.push { title: 'Resend Invitation', key: 'resend', onClick: @props.handleInvitation.bind(this, @props.member, 'resend') }
      items.push { title: 'Revoke Invitation', key: 'revoke', onClick: @props.handleInvitation.bind(this, @props.member, 'revoke') }
    else if role is 'disabled'
      items.push { title: 'Remove Permenantly', key: 'delete', onClick: @props.handleDisabledUser.bind(this, @props.member, 'delete') }
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

    { nickname, email, role, firstName, lastName, fullName } = @getData()

    <div>
      <AvatarView member={@props.member} />
      <div className='details'>
        <div className='fullname'>{fullName}</div>
        <div className='metaData'>
          <Email email={email} />
          <NickName nickname={nickname}/>
        </div>
      </div>
      <MemberRoleWithDropDownMenu
        userRole={@props.userRole}
        role={role}
        onClick={@onClickMemberRole.bind(this, role)}
        items={@getMenuItems role}
        isMenuOpen={@state.isMenuOpen} />
    </div>


MemberRoleWithDropDownMenu = ({ userRole, role, onClick, items, isMenuOpen }) ->

  if userRole is 'member'
    <div className='dropdown'>
      <MemberRole role={role} userRole={userRole}  />
    </div>
  else
    <div className='dropdown' onClick={onClick}>
      <MemberRole role={role} userRole={userRole} />
      <ButtonWithMenu menuClassName='menu-class' items={items} isMenuOpen={isMenuOpen} />
    </div>


NickName = ({ nickname }) ->

  if nickname.length
  then <span className='nickname'>@{nickname}</span>
  else <i></i>

Email = ({ email }) ->

  <span className='email-js email' title={email}>{email}</span>

AvatarView = ({ member }) ->

  unless member.get 'status'
    <div className='avatarview' href='#'>
      <ProfilePicture account={member.toJS()} height={40} width={40} />
    </div>
  else
    <div className='avatarview default' href='#'>
    </div>


MemberRole = ({ role, userRole }) ->

  role = capitalizeFirstLetter role
  className = if userRole is 'member' then '' else 'role'
  <div className={className}>{role}</div>
