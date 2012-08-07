class UserDump extends MySqlMigrant
  
  workingQueue = []
  workingCount = 15602
  
  @countEm = ->
    client = @getKodingenMysqlClient()
    
    client.connect (err)->
      throw err if err
    
    client.query "USE KODINGEN_SOCIAL", (err)->
      throw err if err
    
    client.query 'SELECT count(*) FROM wp_users', (err, howMany)->
      console.log howMany
  
  @migrate = ->
    UserDump.doQuery()
  
  @insert = ()->
    item = workingQueue.shift()
    
    console.log item
    
    if item
      UserDump.addUserAndAccount item, => @insert()
    else
      @doQuery workingCount

  @doQuery =(start=15602,count=100,end=24375,client=@getKodingenMysqlClient())->
    
    client.query "SELECT * FROM wp_users ORDER BY wp_users.ID LIMIT #{start}, #{count}", (err, wpData)=>
      throw err if err
      
      workingQueue = workingQueue.concat wpData
      workingCount += count
      
      @insert()
    
    #  log "inserting #{count} records starting from #{start}"
    #  wpData.forEach (wpDatum)->
    #    console.log wpDatum
    #    UserDump.addUserAndAccount wpDatum
    #  if start < end
    #    UserDump.doQuery client,start+count,count,end 
    #  else
    #    log "userdump completed at #{end}"
        
  @addUserAndAccount =(wpDatum, callback=noop)->
    log "inserting #{wpDatum.user_login}"
    user = new User
      username      : wpDatum.user_login
      email         : wpDatum.user_email
      password      : wpDatum.user_pass
      registeredAt  : wpDatum.user_registered.valueOf()
    
    account = new Account
      profile     :
        nickname  : wpDatum.user_login
        fullname  : wpDatum.display_name
        avatar    : 'http://www.gravatar.com/avatar/'+crypto.createHash('md5').update(wpDatum.user_email.toLowerCase().trim()).digest('hex')
        status    : wpDatum.user_status
    
    manager = new Manager
      name        : "#{wpDatum.user_login}'s default manager"
    
    account.createdAt = wpDatum.user_registered.valueOf()
    
    DefaultAllocations.applyDefaults account
    
    account.save (err)->
      throw err if err
      user.addOwnAccount account, ->
        manager.save (err)->
          account.addManager manager, ->
            user.save (err)->
              throw err if err
              callback()