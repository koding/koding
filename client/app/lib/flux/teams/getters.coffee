whoami      = require 'app/util/whoami'
toImmutable = require 'app/util/toImmutable'
immutable   = require 'immutable'


loadTeam             = ['TeamStore']
TeamMembersIdStore   = ['TeamMembersIdStore']
UsersStore           = ['UsersStore']
TeamMembersRoleStore = ['TeamMembersRoleStore']
searchInputValue     = ['TeamSearchInputValueStore']
inviteInputs         = ['TeamInviteInputsStore']


membersWithRole = [
  TeamMembersIdStore
  TeamMembersRoleStore
  UsersStore
  (ids, roles, members) ->
    return ids.map (id) ->
      role = roles.get id
      members.get(id).set('role', role)  if role
]


filteredMembersWithRole = [
  TeamMembersIdStore
  membersWithRole
  searchInputValue
  (ids, members, value) ->
    console.log '******'
    return members  if value is ''

    filteredMembers = immutable.Map()

    return filteredMembers.withMutations (filteredMembers) ->
      ids.map (id) ->
        member = members.get id
        re = new RegExp(value, 'i')

        if re.test(member.get('profile').get('email')) or \
        re.test(member.get('profile').get('firstname')) or \
        re.test(member.get('profile').get('lastname'))
          filteredMembers.set(id, member)
]


module.exports = {
  loadTeam
  membersWithRole
  TeamMembersIdStore
  inviteInputs
  searchInputValue
  filteredMembersWithRole
}