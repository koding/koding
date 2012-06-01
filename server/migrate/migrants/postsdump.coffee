class PostsDump extends MySqlMigrant
  
  groups = {}
  
  @fetchGroupByWpGroupId = (wpGroupId, callback)->
    if group = groups[wpGroupId]
      callback null, group
    else
      ModuleData_Deprecated.findOne Group: $elemMatch: data: {wpGroupId}, (err, group)->
        groups[wpGroupId] = group
        callback err, group
  
  accounts = {}
  
  @fetchAccountByUsername = (username, callback)->
    if account = accounts[username]
      callback null, account
    else
      Account.findOne 'profile.nickname': username, (err, account)->
        accounts[username] = account
        callback err, account
  
  @migrate =->
    
    console.log 'Beginning the migration script for WordPress posts...'
    
    client = @getKodingenMysqlClient()
    
    client.connect (err)-> throw err if err
          
    client.query 'USE KODINGEN_SOCIAL'
    
    client.query '
      SELECT * FROM wp_bb_forums forums
      JOIN wp_bp_groups groups
        ON groups.slug = forums.forum_slug'
    
    , (err, wpForums)->
      throw err if err
      
      console.log 'are we here yet?'

      console.log "Found some forums (#{wpForums.length})"
      
      wpForums.forEach (wpForum)->
        
        console.log "Attempting to migrate the topics in the forum \"#{wpForum.forum_name}\" (WP forum id #{wpForum.forum_id})"
        
        client.query '
          SELECT * FROM wp_bb_topics WHERE forum_id = '+wpForum.id
          
        , (err, wpTopics)->
          throw err if err
        
          wpTopics.forEach (wpTopic)->
            
            console.log 'Attempting to migrate forum topic '+wpTopic.topic_title
            
            PostsDump.fetchGroupByWpGroupId wpForum.group_id, (err, group)->
              throw err if err
            
              client.query '
                SELECT posts.*, users.user_login AS username
                FROM wp_bb_posts posts
                  JOIN wp_users users ON posts.poster_id = users.ID
                WHERE topic_id = '+wpTopic.topic_id
            
              , (err, wpPosts)->
                throw err if err
              
                rootPost = (wpPost for wpPost in wpPosts when wpPost.post_position is 1)[0]
                rootCreatedAt = rootPost.post_time.valueOf()
                
                console.log 'Adding root post...', rootPost
                
                PostsDump.fetchAccountByUsername rootPost.username, (err, rootAccount)->
                  throw err if err
                
                  post = new Message_Post
                    origin:     rootAccount.getId()
                    originIp:   rootPost.poster_ip
                    subject:    wpTopic.topic_title
                    body:       rootPost.post_text
                    createdAt:  rootCreatedAt
                    modifiedAt: rootCreatedAt
                                      
                  post.save (err)->
                    throw err if err
                  
                    wpPosts.forEach (wpPost)->
                      unless wpPost.post_position is 1
                        
                        console.log 'Adding reply post...', wpPost
                        
                        PostsDump.fetchAccountByUsername wpPost.username, (err, replyAccount)->
                        
                          replyCreatedAt = wpPost.post_time.valueOf()
                          
                          try
                            post.addReply
                              origin:     replyAccount.getId()
                              originIp:   wpPost.poster_ip
                              body:       wpPost.post_text
                              createdAt:  replyCreatedAt
                              modifiedAt: replyCreatedAt
                        
                            , (err)->
                              if err
                                console.log 'the err returned by the "save"'
                                throw err
                              
                          catch err
                            console.log '-------------------------------'
                            console.log 'There was a problem with a post'
                            console.log err
                            console.log post
                            console.log '-------------------------------'