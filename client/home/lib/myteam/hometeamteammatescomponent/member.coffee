kd    = require 'kd'
React = require 'kd-react'
ProfilePicture = require 'app/components/profile/profilepicture'
MakeMember = require './rolecomponents/makemember'
AdminMenuItems = require './rolecomponents/adminmenuitems'
MemberMenuItems = require './rolecomponents/membermenuitems'


module.exports = class Member extends React.Component

  componentWillMount: ->
    @setState
      isRoleSettingsHidden: yes


  onClickMemberRole: ->
    @setState
      isRoleSettingsHidden: not @state.isRoleSettingsHidden


  renderRoleSettings: (role) ->

    if role is 'owner'
      <MakeMember member={@props.member} />
    else if role is 'admin'
      <AdminMenuItems member={@props.member} />
    else # member
      <MemberMenuItems member={@props.member} />

  render: ->

    nickname  = @props.member.getIn(['profile', 'nickname'])
    email     = @props.member.getIn(['profile', 'email'])
    role      = @props.member.get 'role'
    firstName = @props.member.getIn(['profile', 'firstName'])
    lastName  = @props.member.getIn(['profile', 'lastName'])
    fullName  = "#{firstName} #{lastName}"

    isRoleSettingsHidden = if @state.isRoleSettingsHidden then 'hidden' else ''
    settingsClassName = kd.utils.curry 'settings', isRoleSettingsHidden

    <div className='kdview kdlistitemview kdlistitemview-member'>
      <div className='details'>
        <AvatarView member={@props.member} />
        <p className='fullname'>{fullName}</p>
        <p className='nickname'>  @{nickname}</p>
      </div>
      <Email email={email} />
      <span onClick={@bound 'onClickMemberRole'}>
        <MemberRole role={role} />
      </span>
      <div className='clear'></div>
      <div className={settingsClassName}>
        {@renderRoleSettings role}
      </div>
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
  <div className={className}>
    {role}
    <span className='settings-icon'></span>
  </div>
