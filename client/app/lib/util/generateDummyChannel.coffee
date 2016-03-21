module.exports = ({ channelId, channelName, typeConstant, privacyConstant, group, accountOldId, createdAt, participantsPreview }) ->

  channelName = if channelName or channelName is '' then channelName else 'dummy-channel'

  return {
    id                  : channelId or '6089984394406133765'
    _id                 : channelId or '6089984394406133765'
    accountOldId        : accountOldId or '568b34b24868cdaf029fccee'
    bongo_              : {}
    createdAt           : createdAt or '2016-01-05T03:43:46.067543Z'
    creatorId           : '18'
    deletedAt           : '0001-01-01T00:00:00Z'
    groupName           : group or 'dummy-group'
    isParticipant       : true
    metaBits            : 0
    name                : channelName
    participantCount    : 2
    participantsPreview : participantsPreview or [
      {
        _id             : '568b34b24868cdaf029fcce4'
        constructorName : 'JAccount'
      },
      {
        _id             : '568b34b24868cdaf029fccee'
        constructorName : 'JAccount'
      }
    ]
    privacyConstant     : privacyConstant or 'public'
    purpose             : 'dummy-purpose'
    token               : '85f7ee00-b35e-11e5-8e39-d559532fe860'
    typeConstant        : typeConstant or 'topic'
    unreadCount         : 0
    updatedAt           : '2016-01-05T03:43:46.067543Z'
  }
