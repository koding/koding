AccountSettingLists.develop.databasesController = class AccountDatabaseListController extends KDListViewController
  constructor:->
    super
    @account = KD.getSingleton('mainController').getVisitor().currentDelegate
    list = @getListView()

    list.registerListener
      KDEventTypes  : "DatabaseListItemReceivedClick"
      listener      : @
      callback      : (pubInst,item)=>
        data = item.getData()
        @getListView().showAddExternalOrUpdateModal item
        

  loadView:->
    super
    @loadItems =>
      @getListView().attachListeners()
    @getView().parent.addSubView addButton = new KDButtonView
      style     : "clean-gray account-header-button"
      title     : ""
      icon      : yes
      iconOnly  : yes
      iconClass : "plus"
      callback  : ()=>
        @getListView().showAddModal()

  loadItems:(callback)->
    @account.fetchDatabases (err,databases)=>
      @instantiateListItems databases
      callback?()




AccountSettingLists.develop.databases = class AccountDatabaseList extends KDListView
  constructor:(options,data)->
    options = $.extend
      tagName       : "ul"
      subItemClass  : AccountDatabaseListItem
    ,options
    super options,data

  attachListeners:()->
    @items.forEach (item)=>
      item.getData().on "update",()->
        log "update event called:",item
        item.updatePartial item.partial item.getData()

  # viewAppended:->
  #   super
  #   @propagateEvent KDEventType : "ListViewIsReady"

  showAddModal : ->
    
    modal = @modal = new KDModalViewWithForms
      title     : "Add a Database"
      content   : ""
      overlay   : yes
      cssClass  : "new-kdmodal"
      width     : 500
      height    : "auto"
      tabs    :
        navigateable    : yes
        goToNextFormOnSubmit  : no
        callback      : (formOutput)-> log formOutput
        forms     :
          "On Koding" :
            callback      : => 
              @addDatabase
                type : modal.modalTabs.forms["On Koding"].inputs.Type.getValue()
                name : modal.modalTabs.forms["On Koding"].inputs.Name.getValue()          
            buttons :
              "Create":
                title         : "Next"
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
            fields    :
              Type    :
                label       : "Type"
                itemClass   : KDSelectBox 
                type        : "select"
                name        : "type"
                defaultValue: "JDatabaseMySql"
                selectOptions : [
                  { title : "MySql",    value : "JDatabaseMySql" }
                  { title : "Mongo",    value : "JDatabaseMongo" }
                  # { title : "PostGre",  value : "JDatabasePostGre" }
                  # { title : "CouchDB",  value : "JDatabaseCouchDb" }
                ]
              Kind :
                label       : "Kind"
                itemClass   : KDSelectBox 
                type        : "select"
                name        : "type"
                defaultValue: "free"
                selectOptions : [
                  { title : "Free Database for Development",  value : "free" }
                  # { title : "Hit Resistant (n/a)",            value : "hitResistant" }
                  # { title : "Indestructible (n/a)",           value : "indestructible" }
                ]
              Name  :
                label       : "Pick a name"
                name        : "name"
                placeholder : "e.g. myDevDB..."
                defaultValue: "myDB#{(Date.now()+"").substr(-5)}"


  showAddExternalOrUpdateModal:(listItem)=>

    @_listItemToBeUpdated = listItem
    data                  = listItem.getData()
    {type}                = data

    formSchema =
      title     : unless data then "Link External Database" else "Update Database"
      content   : ""
      overlay   : yes
      cssClass  : "new-kdmodal"
      width     : 500
      height    : "auto"
      tabs      :
        forms   : {}
            
    fields =
      Type    :
        label       : "Type"
        name        : "type"
        defaultValue: data?.type.replace "JDatabase",""
        attributes  : {readonly  : yes}        
      Title :
        label       : "Friendly name"
        name        : "title"
        placeholder : "e.g. myDevDB..."
        defaultValue: data.title if data
        nextElement :
          Color :
            itemClass : KDSelectBox           
            type        : "select"
            name        : "color"
            label       : "Color"
            defaultValue: data?.color ? "none"
            selectOptions : [
              { title : "No Color", value : "none"   }
              { title : "White",    value : "white"  }
              { title : "Red",      value : "red"    }
              { title : "Gray",     value : "gray"   }
              { title : "Orange",   value : "orange" }
              { title : "Yellow",   value : "yellow" }
              { title : "Green",    value : "green"  }
              { title : "Blue",     value : "blue"   }
              { title : "Purple",   value : "purple" }
            ]
      Hostname :
        label       : "Hostname"
        name        : "host"
        placeholder : "url//to.your.database.host..."
        defaultValue: data?.host
        attributes  : {readonly  : yes}
      'Database Name' :
        label       : "Database name"
        name        : "name"
        placeholder : "e.g. wp1234"
        defaultValue: data?.name
        attributes  : {readonly  : yes}
      Username :
        label       : "Username to DB"
        name        : "username"
        placeholder : "not koding username..."
        defaultValue: data?.users?[0]?.username
        attributes  : {readonly  : yes}
      Password  :
        label       : "Password to DB"
        name        : "password"
        placeholder : "not koding password..."
        defaultValue: data?.users?[0]?.password
        
    if type is "external"                                     
      formSchema.tabs.forms["Link External"] =
        buttons :
          "Link It!" :
            title         : "Add External Database"
            style         : "modal-clean-gray"
            type          : "submit"
            loader        :
              color       : "#444444"
              diameter    : 12
            callback      : -> console.log arguments
        fields  : fields

    else
      formSchema.tabs.forms["Update Database"] =
        callback  : (formElements)=>
          #console.log "form update",formElements
          @updateDatabase listItem,formElements
        buttons :
          "Update" :
            style         : "modal-clean-gray"
            type          : "submit"
            loader        :
              color       : "#444444"
              diameter    : 12
            callback      : ->
              # log "uuuu"
          "Delete" :
            style         : "modal-clean-red"
            # name          : "clickedButton"
            # value         : "delete"
            # type          : "submit"
            callback      : (pubInst,formElements)=>
              # log "dddd"
              @deleteDatabase listItem,formElements
        fields  : fields
    
    modal = @modal = new KDModalViewWithForms formSchema
          
  addDatabase:(f)=>
  
    jr = new bongo.api[f.type]
      title : f.title   ? "My Dev DB #{(Date.now()+"").substr(-2)}"
      host  : f.host    ? "localhost"
      color : f.color   ? "yellow"
      name  : f.name    ? "My Database #{(Date.now()+"").substr(-5)}"
      users : [
        username  : f.username ? "myUser#{(Date.now()+"").substr(-5)}",
        password  : f.password ? Date.now()
      ]
    .save (err,model)=>
      unless err
        log "added",jr,f
        jr.type = f.type
        itemView = @itemClass delegate:@,jr 
        @addItemView itemView
        @modal.destroy()
      else
        log "failed to add.",err

  deleteDatabase:(listItem,formElements)=>
    jr = listItem.getData()
    jr.remove (err)=>
      if err
        log "failed to delete",err
      else 
        @removeListItem @_listItemToBeUpdated 
        @modal.destroy()

  updateDatabase:(listItem,f)=>
    jr = listItem.getData()
    jr.title  = f.title  ? jr.title
    jr.color  = f.color  ? jr.color
    jr.users[0].password = f.password
    
    jr.update (err)->
      unless err
        log "updated",jr
      else
        log "failed to update",err
    
    @modal.destroy()





class AccountDatabaseListItem extends KDListItemView
  constructor:(options = {},data)->
    options.tagName = "li"
    super options,data
    
  click:(event)=>
    # if @wasClickOn(".action-link") then @getDelegate().emit "ShowAddEditModal",@getData(),@
    if $(event.target).is ".action-link"
      list = @getDelegate()
      list.propagateEvent (KDEventType : "DatabaseListItemReceivedClick"), @

  partial:(data)->
    # log data
    """
      <div class='labelish'>
        <span class='icon #{data.color}'></span>
        <span class='database-title lightText'>#{data.title}</span>
      </div>
      <div class='swappableish swappable-wrapper posstatic'>
        <span class='blacktag'>#{data.type.replace "JDatabase",""}</span>
        #{data.users[0].username+"@"+data.host+"/"+data.name}
        <!-- <cite class='small-text darkText'>last commit: #{data.lastCommitAt}</cite> -->
      </div>
      <a href='#' class='action-link'>Edit</a>
    """



































