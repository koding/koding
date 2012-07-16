class AccountDatabaseListController extends KDListViewController
  constructor:->
    super
    @account = KD.getSingleton('mainController').getVisitor().currentDelegate

    @commands =
      mysql    :
        create : "createMysqlDatabase"
        remove : "removeMysqlDatabase"
        update : "changeMysqlPassword"
        fetch  : "fetchMysqlDatabases"
      mongo    :
        create : "createMongoDatabase"
        remove : "removeMongoDatabase"
        update : "changeMongoPassword"
        fetch  : "fetchMongoDatabases"

    list = @getListView()

    list.registerListener
      KDEventTypes  : "DatabaseListItemReceivedClick"
      listener      : @
      callback      : (pubInst,item)=>
        data = item.getData()
        @getListView().showAddExternalOrUpdateModal item
        

  loadView:->

    super
    list = @getListView()
    @loadItems()
    
    @getView().parent.addSubView addButton = new KDButtonView
      style     : "clean-gray account-header-button"
      title     : ""
      icon      : yes
      iconOnly  : yes
      iconClass : "plus"
      callback  : ()=> list.showAddModal()
        
    list.on "DeleteDatabaseSubmitted", (listItem)=> @deleteDatabase listItem
    list.on "UpdateDatabaseSubmitted", (listItem, formdata)=> @updateDatabase listItem, formdata
    list.on "AddDatabaseSubmitted", => @addDatabase()

    @on "DatabaseDeleted", (listItem)=> list.removeItem listItem
    @on "DatabaseUpdated", (listItem)=>
    @on "DatabaseAdded", (itemData)=> 
      list.addItem itemData, null, {type : "slideDown", duration : 100}
      new KDModalView
        title   : "New Database Information"
        width   : 500
        overlay : yes
        content : """
                  <div class='modalformline'>
                    <p><label>Host:</label> <i>#{itemData.dbHost}</i></p>
                    <p><label>Name:</label> <i>#{itemData.dbName}</i></p>
                    <p><label>User:</label> <i>#{itemData.dbUser}</i></p>
                    <p><label>Password:</label> <b>#{itemData.dbPass}</b></p>
                  </div>
                  <div class='modalformline'>
                    <p>This is an one time password, please keep it somewhere safe you won't be able to reveal it again, but you'll always be able to reset it from here.</p>
                  </div>
                  """

  loadItems:(callback)->
    
    for dbtype in ['mysql', 'mongo']
      @talkToKite
        toDo      : @commands[dbtype].fetch
        withArgs  :
          dbUser  : KD.whoami().profile.nickname
      , (err, response)=>
        log "RESPONSE: ", response
        if err then warn err
        else
          @instantiateListItems response
          callback?()

  deleteDatabase:(listItem)->
    data     = listItem.getData()
    @talkToKite
      toDo     : @commands[data.type].remove
      withArgs :
        dbUser : data.dbUser
        dbName : data.dbName
    , (err, response)=>
      {modal} = @getListView()
      modal.modalTabs.forms["Update Database"].buttons.Delete.hideLoader()
      if err
        @notify "An error occured, try again later!", "error"
      else
        @notify "Database deleted!", "succes"
        @emit "DatabaseDeleted", listItem
        modal.destroy()

  updateDatabase:(listItem, formData)->

    data = listItem.getData()
    log "Requested DB Type", data
    
    @talkToKite
      toDo          : @commands[data.type].update
      withArgs      :
        dbUser      : data.dbUser
        newPassword : formData.password
    , (err, response)=>
      {modal} = @getListView()
      modal.modalTabs.forms["Update Database"].buttons.Update.hideLoader()
      if err
        @notify "An error occured, try again later!", "error"
      else
        @notify "Database updated!", "succes"
        @emit "DatabaseUpdated", listItem
        modal.destroy()

  addDatabase:->

    dbtype = @getListView().modal.modalTabs.forms["On Koding"].inputs.Type.getValue()

    {nickname} = KD.whoami().profile
    pass    = md5.digest("#{Math.random()*1e18}") + md5.digest("#{Math.random()*1e18}")
    dbName  = md5.digest("#{Math.random()*1e18}").substr(-(15-nickname.length))
    dbUser  = dbName
    dbPass  = pass.substr(-40)
    
    @talkToKite
      toDo      : @commands[dbtype].create
      withArgs  : {dbName, dbUser, dbPass}
    , (err, response)=>
      {modal} = @getListView()
      modal.modalTabs.forms["On Koding"].buttons.Create.hideLoader()
      log "ADDED: ", response
      if err
        @notify "An error occured, try again later!", "error"
      else
        @notify "Database created!", "succes"
        @emit "DatabaseAdded", response
        modal.destroy()
  
  talkToKite:(options, callback)->

    log "Run on kite:", options.toDo
    @getSingleton("kiteController").run
      kiteName  : "databases"
      toDo      : options.toDo
      withArgs  : options.withArgs
    , (err, response)=>
      if err then warn err
      callback? err, response
  
  notify:(title, type)->
    
    {modal} = @getListView()
    new KDNotificationView
      type      : "mini"
      cssClass  : "#{type}"
      title     : "<p>#{title}</p>"
      container : modal if type is "error"

class AccountDatabaseList extends KDListView

  constructor:(options,data)->

    options = $.extend
      tagName       : "ul"
      subItemClass  : AccountDatabaseListItem
    ,options
    super options,data

  # attachListeners:()->
  # 
  #   @items.forEach (item)=>
  #     item.getData().on "update",()->
  #       log "update event called:",item
  #       item.updatePartial item.partial item.getData()

  # viewAppended:->
  #   super
  #   @propagateEvent KDEventType : "ListViewIsReady"

  showAddModal : ->
    
    modal = @modal = new KDModalViewWithForms
      title                   : "Add a Database"
      content                 : ""
      overlay                 : yes
      cssClass                : "new-kdmodal"
      width                   : 500
      height                  : "auto"
      tabs                    :
        navigateable          : yes
        goToNextFormOnSubmit  : no
        # callback              : (formOutput)-> log formOutput
        forms                 :
          "On Koding"         :
            callback          : => @emit "AddDatabaseSubmitted"
            buttons           :
              Create          :
                title         : "Create"
                style         : "modal-clean-gray"
                type          : "submit"
                loader        :
                  color       : "#444444"
                  diameter    : 12
              # "Link External" :
              #   title       :  "Link External"
              #   style       : "modal-clean-gray"
              #   callback : =>
              #     @modal.destroy()
              #     @showAddExternalOrUpdateModal null,null,"external"
            fields            :
              Type            :
                label         : "Type"
                itemClass     : KDSelectBox 
                type          : "select"
                name          : "type"
                defaultValue  : "mysql"
                selectOptions : [
                  { title : "MySql",    value : "mysql" }
                  { title : "Mongo",    value : "mongo" }
                  # { title : "PostGre",  value : "JDatabasePostGre" }
                  # { title : "CouchDB",  value : "JDatabaseCouchDb" }
                ]
              Kind            :
                label         : "Kind"
                itemClass     : KDSelectBox 
                type          : "select"
                name          : "type"
                defaultValue  : "free"
                selectOptions : [
                  { title : "Free Database for Development",  value : "free" }
                  # { title : "Hit Resistant (n/a)",            value : "hitResistant" }
                  # { title : "Indestructible (n/a)",           value : "indestructible" }
                ]
              # Name  :
              #   label       : "Pick a name"
              #   name        : "name"
              #   placeholder : "e.g. myDevDB..."
              #   defaultValue: "myDB#{(Date.now()+"").substr(-5)}"


  showAddExternalOrUpdateModal:(listItem)=>

    @_listItemToBeUpdated = listItem
    data                  = listItem.getData()
    {type}                = data

    formSchema =
      title     : unless data then "Link External Database" else "Edit/Delete Database"
      content   : ""
      overlay   : yes
      cssClass  : "new-kdmodal"
      width     : 500
      height    : "auto"
      tabs      :
        forms   : {}
            
    fields =
      # Type    :
      #   label       : "Type"
      #   name        : "type"
      #   defaultValue: "mysql"
      #   attributes  : {readonly  : yes}        
      # Title :
      #   label       : "Friendly name"
      #   name        : "title"
      #   placeholder : "e.g. myDevDB..."
      #   defaultValue: data.title if data
      #   nextElement :
      #     Color :
      #       itemClass : KDSelectBox           
      #       type        : "select"
      #       name        : "color"
      #       label       : "Color"
      #       defaultValue: data?.color ? "none"
      #       selectOptions : [
      #         { title : "No Color", value : "none"   }
      #         { title : "White",    value : "white"  }
      #         { title : "Red",      value : "red"    }
      #         { title : "Gray",     value : "gray"   }
      #         { title : "Orange",   value : "orange" }
      #         { title : "Yellow",   value : "yellow" }
      #         { title : "Green",    value : "green"  }
      #         { title : "Blue",     value : "blue"   }
      #         { title : "Purple",   value : "purple" }
      #       ]
      # Hostname        :
      #   label         : "Hostname"
      #   name          : "host"
      #   placeholder   : "url//to.your.database.host..."
      #   defaultValue  : data?.dbHost
      #   attributes    : {readonly  : yes}
      # 'Database Name' :
      #   label         : "Database name"
      #   name          : "name"
      #   placeholder   : "e.g. wp1234"
      #   defaultValue  : data?.dbName
      #   attributes    : {readonly  : yes}
      # Username        :
      #   label         : "Username to DB"
      #   name          : "username"
      #   placeholder   : "not koding username..."
      #   defaultValue  : data?.dbUser
      #   attributes    : {readonly  : yes}
      "New Password"      :
        label             : "New Password"
        name              : "password"
        placeholder       : "reset db password..."
      # "Confirm Password"  :
      #   label             : "New Password"
      #   name              : "password"
      #   placeholder       : "reset db password..."
      #   validate          :
      #     rules           :
      #       match         : @modal.modalTabs.forms.fields['New Password']
      #     messages        :
      #       match         : "Passwords do not match!"
        
    if type is "external"                                     
      formSchema.tabs.forms["Link External"] =
        buttons :
          "Link It!"      :
            title         : "Add External Database"
            style         : "modal-clean-gray"
            type          : "submit"
            loader        :
              color       : "#444444"
              diameter    : 12
        fields            : fields

    else
      formSchema.tabs.forms["Update Database"] =
        callback          : (formData)=> @emit "UpdateDatabaseSubmitted", listItem, formData
        buttons           :
          Update          :
            style         : "modal-clean-gray"
            type          : "submit"
            loader        :
              color       : "#444444"
              diameter    : 12
          Delete          :
            style         : "modal-clean-red"
            loader        :
              color       : "#444444"
              diameter    : 12
            callback      : =>
              modal.modalTabs.forms['Update Database'].buttons.Delete.hideLoader()
              modal.modalTabs.forms['Update Database'].buttons.Update.hide()
              unless modal._sureToDelete
                field = modal.modalTabs.forms['Update Database'].fields['New Password']
                field.$('*').hide()
                field.$().append "Click delete again to delete the database, <b>be aware there is no way back!</b>"
                modal._sureToDelete = yes
              else
                delete modal._sureToDelete
                @emit "DeleteDatabaseSubmitted", listItem

        fields  : fields
    
    modal = @modal = new KDModalViewWithForms formSchema
          
  # addDatabase:(f)=>


  
    # jr = new bongo.api[f.type]
    #   title : f.title   ? "My Dev DB #{(Date.now()+"").substr(-2)}"
    #   host  : f.host    ? "localhost"
    #   color : f.color   ? "yellow"
    #   name  : f.name    ? "My Database #{(Date.now()+"").substr(-5)}"
    #   users : [
    #     username  : f.username ? "myUser#{(Date.now()+"").substr(-5)}",
    #     password  : f.password ? Date.now()
    #   ]
    # .save (err,model)=>
    #   unless err
    #     log "added",jr,f
    #     jr.type = f.type
    #     itemView = @itemClass delegate:@,jr 
    #     @addItemView itemView
    #     @modal.destroy()
    #   else
    #     log "failed to add.",err

  # deleteDatabase:(listItem)=>
  #   
  #   jr = listItem.getData()
  #   jr.remove (err)=>
  #     if err
  #       log "failed to delete",err
  #     else 
  #       @removeListItem @_listItemToBeUpdated 
  #       @modal.destroy()
  # 
  # updateDatabase:(listItem, formData)=>
  # 
  #   jr = listItem.getData()
  #   jr.title  = f.title  ? jr.title
  #   jr.color  = f.color  ? jr.color
  #   jr.users[0].password = f.password
  #   
  #   jr.update (err)->
  #     unless err
  #       log "updated",jr
  #     else
  #       log "failed to update",err
  #   
  #   @modal.destroy()





class AccountDatabaseListItem extends KDListItemView
  constructor:(options = {},data)->

    log "Create Item with Data", data

    options.tagName = "li"
    
    data.dbType   or= "mysql"
    data.color    or= if data.type == "mysql" then "yellow" else "green"
    data.title    or= if data.type == "mysql" then "MySql DB" else "Mongo DB"
    data.dbHost   or= "mysql0.db.koding.com"

    super options,data
    
  click:(event)=>

    if $(event.target).is ".action-link"
      list = @getDelegate()
      list.propagateEvent (KDEventType : "DatabaseListItemReceivedClick"), @

  partial:(data)->

    """
      <div class='labelish'>
        <span class='icon #{data.color}'></span>
        <span class='blacktag'>#{data.dbType}</span>
      </div>
      <div class='labelish'>
        <a href='#'>dbname: </a><span class='lightText'>#{data.dbName}</span>
      </div>
      <div class='labelish'>
        <a href='#'>user: </a><span class='lightText'>#{data.dbUser}</span>
      </div>
      <div class='labelish'>
        <a href='#'>host: </a><span class='lightText'>#{data.dbHost}</span>
      </div>
      <a href='#' class='action-link'>Edit</a>
    """




