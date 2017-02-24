module.exports = (client, currentGroup, callback) ->

  async = require 'async'
  JGroup = require '../models/group'
  SocialAccount = require '../models/socialapi/socialaccount'

  accountCreated = no
  account = client?.connection?.delegate
  who = account?.profile?.nickname or account?._id

  # do corrections to data here - if required.
  async.series [

    (next) ->
      return next()  unless account

      return next()  if account.socialApiId

      console.log "#{who} does not have socialapi"

      # if we somehow didnt create socialapi id, create here
      account.createSocialApiId (err) ->
        if err
          console.log "Couldnt create socialapi id for #{who}"
        else
          accountCreated = yes

        next err

    (next) ->
      return next()  unless currentGroup

      if currentGroup.socialApiChannelId
        return next()

      console.log "#{currentGroup.slug} does not have socialapi data"

      # if we somehow dont have required socialapi channels, create them
      currentGroup.createSocialApiChannels client, (err) ->
        if err
          console.log "Couldnt create socialapi channels for #{currentGroup.slug}", err
          return next()

        currentGroup.fetchMembers (err, members) ->
          if err
            console.log "Couldnt fetch members of #{currentGroup.slug}", err
            return next()

          return next() unless members?.length

          # this is fire and forget
          mq = members.map (member) -> (pass) ->
            console.log "Processing #{member.profile.nickname} into #{currentGroup.slug}"
            SocialAccount.addParticipant { group: currentGroup, member: member }, (err) ->
              console.log "err while adding #{member.profile.nickname} into #{currentGroup.slug}", err if err
              pass()

          async.parallel mq, -> next()

          console.log "Created socialapi channels for #{currentGroup.slug}"

    (next) ->
      # if team does not have "defaultChannels" add it back
      return next()  unless currentGroup

      return next() if currentGroup.defaultChannels?.length > 0

      # we might have created the group channel ids' above
      JGroup.one { _id: currentGroup.getId() }, (err, group) ->
        if err
          console.error 'err while trying to fetch group again', err
          next()

        channels = []
        channels.push group.socialApiChannelId if group.socialApiChannelId

        group.update { $set: { 'defaultChannels': channels } }, (err) ->
          if err
            console.log 'err while updating group with defaultChannels', err

          console.log "Created defaultChannels for #{group.slug}"
          return next()

    (next) ->
      # this fixer is special case, where a user might not have a socialapi id
      # but the regarding group might have the data. in any case we should not
      # get in this block. but we might do. ¯\_(ツ)_/¯

      return next()  unless accountCreated
      return next()  unless account

      account.fetchAllParticipatedGroups (err, groups) ->
        if err
          console.log "Couldnt fetch groups of #{who}", err
          return next()

        return next() unless groups?.length

        gq = groups.map (group) -> (pass) ->
          SocialAccount.addParticipant { group: group, member: account }, (err) ->
            console.log "Added #{who} into #{group.slug}"
            pass()

        async.parallel gq, -> next()

  ], -> callback null
