kd                    = require 'kd'
whoami                = require 'app/util/whoami'
KodingListController  = require 'app/kodinglist/kodinglistcontroller'


module.exports = class TeamMembersListController extends KodingListController

  constructor: (options = {}, data) ->

    options.lazyLoadThreshold ?= .99
    options.sort              ?= { timestamp: -1 }

    super options, data


  addListItems: (members, filterForDefaultRole) ->

    { memberType, limit, defaultMemberRole } = @getOptions()

    group = @getData()
    member._currentGroup = group for member in members

    if members.length is 0 and @getItemCount() is 0
      @hideLazyLoader()
      @showNoItemWidget()
      return

    @filterStates.skip += members.length

    if memberType is 'Blocked'
      @addItem member  for member in members
      @emit 'CalculateAndFetchMoreIfNeeded'  if members.length is limit
    else
      @fetchUserRoles members, (members) =>

        if filterForDefaultRole and defaultMemberRole
          members = members.filter (member) ->
            return defaultMemberRole in member.roles

        if members.length
          members.forEach (member) =>
            member.loggedInUserRoles = @loggedInUserRoles # FIXME
            item = @addItem member

          @emit 'CalculateAndFetchMoreIfNeeded'  if members.length is limit
        else
          @showNoItemWidget()

    @hideLazyLoader()
    @emit 'ShowSearchContainer'


  fetchUserRoles: (members, callback = kd.noop) ->

    # collect account ids to fetch user roles
    ids = members.map (member) -> return member.getId()

    myAccountId = whoami().getId()
    ids.push myAccountId

    @getData().fetchUserRoles ids, (err, roles) =>
      return @emit 'ErrorHappened', err  if err

      # create account id and roles map
      userRoles = {}

      # roles array is a flat array which means when you query for an account
      # the response would be 3 items array which contains different roles for
      # the same user. create an array by user and collect all roles belong
      # to that user.
      for role in roles
        list = userRoles[role.targetId] or= []
        list.push role.as

      # save user role array into jAccount as jAccount.role
      for member in members
        roles = userRoles[member.getId()]
        member.roles = roles  if roles

      @loggedInUserRoles = userRoles[myAccountId] ? ['owner', 'admin', 'member']

      callback members
