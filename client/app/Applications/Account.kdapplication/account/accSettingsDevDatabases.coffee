class AccountDatabaseListController extends KDListViewController
  constructor:->
    super
    @account = KD.whoami()

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

    list.on "DatabaseListItemReceivedClick", (item)=>
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

    @getView().parent.addSubView refreshButton = new KDButtonView
      style     : "clean-gray account-header-second-button"
      title     : ""
      icon      : yes
      iconOnly  : yes
      iconClass : "refresh"
      callback  : => @loadItems()

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
    @removeAllItems()
    dbTypes = ['mysql', 'mongo']
    @_loaderCount = dbTypes.length
    @_timeout?.destroy?()
    @showLazyLoader no

    hideLoaderWhenFinished = =>
      @_loaderCount--
      @hideLazyLoader() if @_loaderCount <= 0

    setTimeout =>
      @hideLazyLoader()
      if @_loaderCount > 0
        @_timeout?.destroy?()
        @scrollView.addSubView @_timeout = new KDCustomHTMLView
          cssClass : "lazy-loader"
          partial  : "Fetching database list failed. <a href='#'>Retry</a>"
          click    : (event)=>
            if $(event.target).is "a"
              @loadItems()
              @_timeout.destroy()
    , 10000

    responseAdded = []
    for dbtype in dbTypes
      @talkToKite
        method : @commands[dbtype].fetch
      , (err, response)=>
        if err then warn err
        else
          if response.length > 0
            unless response[0].dbName in responseAdded
              @instantiateListItems response
              responseAdded.push response[0].dbName
          callback?()
          hideLoaderWhenFinished()

  deleteDatabase:(listItem)->
    data     = listItem.getData()
    @talkToKite
      method   : @commands[data.dbType].remove
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
      method        : @commands[data.dbType].update
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
    dbUser = dbName = __utils.generatePassword 15-nickname.length, yes
    dbPass = __utils.generatePassword 40, no

    @talkToKite
      method      : @commands[dbtype].create
      withArgs  : {dbName, dbUser, dbPass}
    , (err, response)=>
      {modal} = @getListView()
      modal.modalTabs.forms["On Koding"].buttons.Create.hideLoader()
      if err
        @notify err.message or "An error occured, try again later!", "error"
      else
        @notify "Database created!", "succes"
        @emit "DatabaseAdded", response
        modal.destroy()

  talkToKite:(options, callback)->

    # log "Run on kite:", options.method
    @getSingleton("kiteController").run
      kiteName  : "databases"
      method    : options.method
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
      duration  : 3000

class AccountDatabaseList extends KDListView

  constructor:(options,data)->

    options = $.extend
      tagName       : "ul"
      itemClass  : AccountDatabaseListItem
    ,options
    super options,data

  showAddModal : ->

    modal = @modal = new KDModalViewWithForms
      title                   : "Add a Database"
      content                 : ""
      overlay                 : yes
      cssClass                : "new-kdmodal"
      width                   : 500
      height                  : "auto"
      tabs                    :
        navigable          : yes
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



    # jr = new KD.remote.api[f.type]
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
    #     itemView = new (@getOptions().itemClass ? KDListItemView) delegate:@,jr
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

    # log "Create Item with Data", data

    options.tagName = "li"

    data.color or= if data.dbType == "mysql" then "yellow" else "green"
    data.title or= if data.dbType == "mysql" then "MySql DB" else "Mongo DB"

    super options,data

  click:(event)=>

    if $(event.target).is ".action-link"
      list = @getDelegate()
      list.emit "DatabaseListItemReceivedClick", @

  partial:(data)->

    """
      <div class='labelish'>
        <span class='icon #{data.color}'></span>
        <span class='blacktag'>#{data.dbType}</span>
      </div>
      <div class='labelish'>
        <a href='#'>dbname / user: </a><span class='lightText'>#{data.dbName}</span>
      </div>
      <div class='labelish'>
        <a href='#'>host: </a><span class='lightText'>#{data.dbHost}</span>
      </div>
      <a href='#' class='action-link'>Edit</a>
    """
