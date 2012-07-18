class GroupsDump extends MySqlMigrant
    
  wpGroupIds = []
  
  @migrate =->
    
    client = @getKodingenMysqlClient()
    
    client.connect (err)-> throw err if err
    
    client.query 'USE KODINGEN_SOCIAL'
    
    client.query 'SELECT DISTINCT groups.* FROM wp_bp_groups groups LIMIT 100'
      
      , (err, wpData)->
        
        throw err if err
        
        groupsCount = wpData.length
        counter     = 0
        
        wpData.forEach (wpGroup)->
          
          client.query 'SELECT user_login AS username FROM wp_users WHERE ID = '+wpGroup.creator_id, (err, wpUserData)->
            creator = wpUserData.shift().username
            
            {name, description} = wpGroup
            
            if /^http:\/\/kodingen.com/.test wpGroup.avatar_full
              
              fixUrlRegExp = /(^http:\/\/kodingen.com\/)(.+)/
              fixUrlFn     = (a,b,c)-> b+'w/'+c
              
              avatar       = wpGroup.avatar_full .replace fixUrlRegExp, fixUrlFn
              avatarThumb  = wpGroup.avatar_thumb.replace fixUrlRegExp, fixUrlFn
            
            else
              
              avatar       = wpGroup.avatar_full
              avatarThumb  = wpGroup.avatar_thumb  
            
            
            GroupsDump.fetchAvatarFromScrape wpGroup, avatar, avatarThumb, (avatar, avatarThumb)->

              createdAt = wpGroup.date_created.valueOf()
            
              isPrivate = 
                switch wpGroup.status
                  when 'private', 'hidden' then yes else no
            
              byInviteOnly = wpGroup.status is 'hidden'
            
              group = new Group {
                name
                description
                avatar
                avatarThumb
                isPrivate
                byInviteOnly
                createdAt
                data: wpGroupId: wpGroup.id
              }
            
              group.createdAt = createdAt
              
              group.save (err)->
                throw err if err
                
                GroupsDump.assignOwnershipToGroup group, creator
                wpGroupIds.push wpGroup.id
                if ++counter is groupsCount
                  GroupsDump.assignMembershipsToGroup group
  
  
  getKodingenAvatarPath =(wpGroupId, file)->
    "http://kodingen.com/w/files/group-avatars/#{wpGroupId}/#{file}"
  
  @fetchAvatarFromScrape =(wpGroup, avatar, avatarThumb, callback)->
    if avatar and avatarThumb
      callback avatar, avatarThumb
    
    else
      
      options = 
        host: "kodingen.com"
        port: 80
        path: "/yo.php?id="+wpGroup.id

      req = require("http").request options, (res) ->
        res.setEncoding "utf8"
        
        avatarData = ''
        
        res.on 'data', (chunk) ->
          avatarData += chunk
        
        res.on 'end', ->
          _(JSON.parse avatarData).chain()
            .each (file)->
              if /full/.test file
                avatar = getKodingenAvatarPath wpGroup.id, file
              else if /thumb/.test file
                avatarThumb = getKodingenAvatarPath wpGroup.id, file
          
          callback avatar, avatarThumb
      
      req.on "error", (e) ->
        console.log "problem with request: " + e.message

      req.write "this feels\n"
      req.write "like a hack\n"
      req.end()
    
  
  @assignMembershipsToGroup = (group)->
    
    client = @getKodingenMysqlClient()
    
    wpGroupIds.forEach (wpGroupId)->
      client.query sql = '
        SELECT DISTINCT
          memberships.*,
          members.user_login AS member_username,
          inviters.user_login AS inviter_username 
        FROM wp_bp_groups_members memberships
          LEFT JOIN wp_users members ON members.ID = memberships.user_id
          LEFT JOIN wp_users inviters ON inviters.ID = memberships.inviter_id
        WHERE memberships.group_id = '+wpGroupId+'
        AND is_banned = 0 AND is_confirmed = 1' # TODO: shouldn't we import these guys, even if they are unconfirmed or banned
      
        , (err, wpDataMemberships)->
        
          if wpDataMemberships
            console.log "Found #{wpDataMemberships.length} member results for #{wpGroupId}.  Adding membership..."

            wpDataMemberships.forEach (membership)->
              Account.findOne 'profile.nickname': membership.member_username, (err, member)->
                throw err if err
              
                if member
                  console.log 'found a member - '+member.get().profile.nickname 
                  
                  member.addGroup group,
                    if membership.is_mod then 'moderator' else 'member'
                
                inviter = membership.inviter_username
                
                if inviter? and inviter isnt 'admin'
                
                  Account.findOne 'profile.nickname': membership.inviter_username, (err, inviter)->
                    throw err if err
                  
                    if inviter
                      invitation = new Message_Invitation
                        origin    : inviter.getId()
                        subject   : "You've been invited to the group \"#{name}\"."
                    
                      invitation.save (err)->
                        throw err if err
                      
                        module.addInvitation(invitation) for module in [group, member]
  
  @assignOwnershipToGroup = (group, creator)->
  
    Account.findOne 'profile.nickname': creator, (err, account)->
      throw err if err
  
      if account
        account.addGroup group