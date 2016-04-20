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


  getMenuItems: (role) ->
    
    items=[]
    
    if role is 'owner'
      items.push { title: 'MAKE MEMBER', key: 'makemember', onClick: @props.handleRoleChange.bind(this, @props.member, 'member') }
    else if role is 'admin'
      items.push { title: 'MAKE MEMBER', key: 'makemember', onClick: @props.handleRoleChange.bind(this, @props.member, 'member') }
      items.push { title: 'MAKE OWNER', key: 'mameowner', onClick: @props.handleRoleChange.bind(this, @props.member, 'owner') }
      items.push { title: 'DISABLE USER', key: 'disableuser', onClick: @props.handleRoleChange.bind(this, @props.member, 'kick') }
    else
      items.push { title: 'MAKE OWNER', key: 'makemember', onClick: @props.handleRoleChange.bind(this, @props.member, 'owner') }
      items.push { title: 'MAKE ADMIN', key: 'makeadmin', onClick: @props.handleRoleChange.bind(this, @props.member, 'admin') }
      items.push { title: 'DISABLE USER', key: 'disableuser', onClick: @props.handleRoleChange.bind(this, @props.member, 'kick') }
      
    return items


  render: ->
       
    nickname  = @props.member.getIn(['profile', 'nickname'])
    email     = @props.member.getIn(['profile', 'email'])
    role      = @props.member.get 'role'
    firstName = @props.member.getIn(['profile', 'firstName'])
    lastName  = @props.member.getIn(['profile', 'lastName'])
    fullName  = "#{firstName} #{lastName}"

    <div className='kdview kdlistitemview kdlistitemview-member'>
      <div className='details'>
        <AvatarView member={@props.member} />
        <p className='fullname'>{fullName}</p>
        <p className='nickname'>  @{nickname}</p>
      </div>
      <Email email={email} />
      <span onClick={@onClickMemberRole.bind(this, role)}>
        <MemberRole role={role} />
      </span>
      <div className='clear'></div>
      <ButtonWithMenu menuClassName='menu-class' items={@getMenuItems role} isMenuOpen={@state.isMenuOpen} />
    </div>


Email = ({ email }) ->

  <p className='email' title={email}>{email}</p>

AvatarView = ({ member }) ->

  <span className='avatarview' href='#'>
    <ProfilePicture account={member.toJS()} height={40} width={40} />
    <cite className='super-admin'></cite>
  </span>


MemberRole = ({ role }) ->
  className = 'role'
  role = capitalizeFirstLetter role
  <div className={className}>
    {role}
    <span className='settings-icon'></span>
  </div>
