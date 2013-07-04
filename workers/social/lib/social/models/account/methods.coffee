# Methods shared by JAccount & JGuest
module.exports =
  sharedStaticMethods:->
    [
      'one', 'some', 'cursor', 'each', 'someWithRelationship'
      'someData', 'getAutoCompleteData', 'count'
      'byRelevance', 'fetchVersion','reserveNames'
      'impersonate'
    ]
  sharedInstanceMethods:->
    [
      'modify','follow','unfollow','fetchFollowersWithRelationship'
      'countFollowersWithRelationship', 'countFollowingWithRelationship'
      'fetchFollowingWithRelationship', 'fetchTopics'
      'fetchMounts','fetchActivityTeasers','fetchRepos','fetchDatabases'
      'fetchMail','fetchNotificationsTimeline','fetchActivities'
      'fetchStorage','count','addTags','fetchLimit', 'fetchLikedContents'
      'fetchFollowedTopics', 'fetchKiteChannelId', 'setEmailPreferences'
      'fetchNonces', 'glanceMessages', 'glanceActivities', 'fetchRole'
      'fetchAllKites','flagAccount','unflagAccount','isFollowing'
      'fetchFeedByTitle', 'updateFlags','fetchGroups','fetchGroupRoles',
      'setStaticPageVisibility','addStaticPageType','removeStaticPageType',
      'setHandle','setAbout','fetchAbout','setStaticPageTitle',
      'setStaticPageAbout', 'addStaticBackground', 'setBackgroundImage',
      'fetchPendingGroupInvitations', 'fetchPendingGroupRequests',
      'cancelRequest', 'acceptInvitation', 'ignoreInvitation',
      'getInvitationRequestByGroup', 'fetchMyPermissions',
      'fetchMyPermissionsAndRoles', 'fetchMyFollowingsFromGraph', 'fetchMyFollowersFromGraph',
      'sendEmailVMTurnOnFailureToSysAdmin'
    ]
