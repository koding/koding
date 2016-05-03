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
      items.push {title: 'Resend Invitation', key: 'resend', onClick: @props.handleInvitation.bind(this, @props.member, 'resend')}
      items.push {title: 'Revoke Invitation', key: 'revoke', onClick: @props.handleInvitation.bind(this, @props.member, 'revoke')}
    else
      items.push { title: 'Make owner', key: 'makemember', onClick: @props.handleRoleChange.bind(this, @props.member, 'owner') }
      items.push { title: 'Make admin', key: 'makeadmin', onClick: @props.handleRoleChange.bind(this, @props.member, 'admin') }
      items.push { title: 'Disable user', key: 'disableuser', onClick: @props.handleRoleChange.bind(this, @props.member, 'kick') }

    return items


  getData: (member) ->

    nickname = member.getIn ['profile', 'nickname']
    email = member.getIn ['profile', 'email']
    role = member.get 'role'
    firstName = member.getIn ['profile', 'firstName']
    lastName = member.getIn ['profile', 'lastName']
    fullName = "#{firstName} #{lastName}"

    if member.get('status') is 'pending'
      role = 'Invitation Sent'
      firstName = member.get('firstName') or ''
      lastName = member.get('lastName') or ''
      fullName = member.get 'email'
      email = "#{firstName} #{lastName}"
      nickname = ''

    return { nickname, email, role, firstName, lastName, fullName }


  render: ->

    { nickname, email, role, firstName, lastName, fullName } = @getData @props.member

    <div className='kdview kdlistitemview kdlistitemview-member'>
      <div className='details'>
        <AvatarView member={@props.member} />
        <p className='fullname'>{fullName}</p>
      </div>
      <Email email={email} />
      <NickName nickname={nickname}/>
      <span onClick={@onClickMemberRole.bind(this, role)}>
        <MemberRole role={role} />
      </span>
      <div className='clear'></div>
      <ButtonWithMenu menuClassName='menu-class' items={@getMenuItems role} isMenuOpen={@state.isMenuOpen} />
    </div>


NickName = ({ nickname }) ->

  if nickname.length
    <p className='nickname'> | @{nickname}</p>
  else
    <p className='nickname'></p>

Email = ({ email }) ->

  <p className='email-js' title={email}>{email}</p>

AvatarView = ({ member }) ->

  unless member.get 'status'
    <span className='avatarview' href='#'>
      <ProfilePicture account={member.toJS()} height={40} width={40} />
      <cite className='super-admin'></cite>
    </span>
  else
    <span className='avatarview' href='#'>
      <cite className='super-admin'></cite>
    </span>


MemberRole = ({ role }) ->
  className = 'role'
  role = capitalizeFirstLetter role
  <div className={className}>
    {role}
    <span className='settings-icon'></span>
  </div>
