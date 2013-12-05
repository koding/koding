{Base} = require 'bongo'

module.exports =

  member      :
    following : (orderByQuery)->
      """
        START group=node:koding(id={groupId})
        MATCH group-[r:member]->members-[:follower]->currentUser
        WHERE currentUser.id = {currentUserId}
        RETURN members
        #{orderByQuery}
        SKIP {skipCount}
        LIMIT {limitCount}
      """
    onlineFollowing : (orderByQuery)->
      """
        START user=node:koding(id={currentUserId})
        MATCH user-[:follower]->members
        WHERE members.onlineStatus! = "online"
        RETURN members
        #{orderByQuery}
        SKIP {skipCount}
        LIMIT {limitCount}
      """
    follower  : (orderByQuery)->
      """
        START group=node:koding(id={groupId})
        MATCH group-[r:member]->members<-[:follower]-currentUser
        WHERE currentUser.id = {currentUserId}
        RETURN members
        #{orderByQuery}
        SKIP {skipCount}
        LIMIT {limitCount}
      """
    list: (exemptClause, orderByQuery)->
      """
        START group=node:koding(id={groupId})
        MATCH group-[r:member]->members
        WHERE members.name="JAccount"
        #{exemptClause}
        RETURN members
        #{orderByQuery}
        SKIP {skipCount}
        LIMIT {limitCount}
      """
    count: (exemptClause)->
      """
      START group=node:koding(id={groupId})
      MATCH group-[:member]->members
      WHERE members.name="JAccount"
      #{exemptClause}
      RETURN count(members) as count
      """
    search: (options)->
      {seed, firstNameRegExp, lastNameRegexp, blacklistQuery, exemptClause} = options
      """
        START koding=node:koding(id={groupId})
        MATCH koding-[r:member]->members

        WHERE  (
          members.`profile.nickname` =~ '(?i)#{seed}'
          and members.type = 'registered'
          or members.`profile.firstName` =~ '(?i)#{firstNameRegExp}'
          or members.`profile.lastName` =~ '(?i)#{lastNameRegexp}'
        )

        #{blacklistQuery}
        #{exemptClause}

        RETURN members
        ORDER BY members.`profile.firstName`
        SKIP {skipCount}
        LIMIT {limitCount}
      """
  bucket      :
    newMembers :
      """
        START group=node:koding(id={groupId})
        MATCH group-[r:member]->members
        WHERE r.createdAtEpoch < {to}
        RETURN members
        ORDER BY r.createdAtEpoch DESC
        LIMIT {limitCount}
      """
    newInstallations :
      """
        START group=node:koding(id={groupId})
        MATCH group-[:member]->users<-[r:user]-apps
        WHERE apps.name="JApp"
        AND r.createdAtEpoch < {to}
        RETURN users, apps, r
        ORDER BY r.createdAtEpoch DESC
        LIMIT {limitCount}
      """
    newUserFollows :
      """
        START group=node:koding(id={groupId})
        MATCH group-[:member]->followees<-[r:follower]-follower
        WHERE follower<-[:member]-group
        AND r.createdAtEpoch < {to}
        RETURN r,followees, follower
        ORDER BY r.createdAtEpoch DESC
        LIMIT {limitCount}
      """
    newTagFollows :
      """
        START koding=node:koding(id={groupId})
        MATCH koding-[:member]->followees<-[r:follower]-follower
        WHERE follower.name="JTag"
          AND follower.group = {groupName}
          AND r.createdAtEpoch < {to}
        RETURN r,followees, follower
        ORDER BY r.createdAtEpoch DESC
        LIMIT {limitCount}
      """
  activity    :
    public :(facetQuery="",groupFilter="", exemptClause="")->
      """
        START group=node:koding(id={groupId})
        MATCH group-[:member]->members<-[:author]-content
        WHERE content.`meta.createdAtEpoch` < {to}
        #{facetQuery}
        #{groupFilter}
        #{exemptClause}
        RETURN content
        ORDER BY content.`meta.createdAtEpoch` DESC
        LIMIT {limitCount}
      """

    following:(facet="", timeQuery="", exemptClause="")->
      """
        START member=node:koding(id={userId})
        MATCH member<-[:follower]-members-[:author]-content
        WHERE members.name="JAccount"
        AND content.group = {groupName}
        #{facet}
        #{timeQuery}
        #{exemptClause}
        RETURN DISTINCT content
        ORDER BY content.`meta.createdAtEpoch` DESC
        LIMIT {limitCount}
      """

    followingnew:(exemptClause="", type="JStatusUpdate")->
      """
        START member=node:koding(id={userId})
        MATCH member<-[:follower]-members-[:author]-content
        WHERE members.name="JAccount"
        AND content.group = {groupName}
        AND content.name = "#{type}"
        #{exemptClause}
        RETURN content.id as id
        ORDER BY content.`meta.createdAtEpoch` DESC
        SKIP {skipCount}
        LIMIT {limitCount}

      """

    profilePage: (options)->
      """
        START member=node:koding(id={userId})
        MATCH member<-[:author]-content
        WHERE content.originId = {userId}
        #{options.facetQuery}
        RETURN content
        ORDER BY #{options.orderBy} DESC
        SKIP {skipCount}
        LIMIT {limitCount}
      """

  invitation  :
    list     :(status, timestampQuery="", searchQuery="")->
      """
        START group=node:koding(id={groupId})
        MATCH group-[r:owner]->groupOwnedNodes
        WHERE groupOwnedNodes.name = 'JInvitationRequest'
        AND groupOwnedNodes.status IN #{status}
        #{timestampQuery}
        #{searchQuery}
        RETURN groupOwnedNodes
        ORDER BY groupOwnedNodes.`meta.createdAtEpoch`
        LIMIT {limitCount}
      """
  aggregation :
    relationshipCount:(relationshipName)->
      """
        START group=node:koding(id={groupId})
        MATCH group-[:#{relationshipName}]->items
        RETURN count(items) as count
      """
