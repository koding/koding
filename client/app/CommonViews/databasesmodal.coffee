class ManageDatabasesModal extends KDModalViewWithForms

  constructor:(options = {}, data)->

    ## LOG: Duplicate entries in database.
    @databases = {}
    ##

    options =
      title                   : "Manage Databases"
      content                 : ''
      helpContent             :
        """
          You can create and modify your databases from this modal.
          Under the **Current Databases** tab you can list current databases
          you have created before and you can use same name for your database
          name and database user name.
        """
      overlay                 : yes
      width                   : 500
      height                  : "auto"
      cssClass                : "databases-modal"
      tabs                    :
        navigable             : yes
        goToNextFormOnSubmit  : no
        forms                 :
          "Create New Database":
            buttons           :
              Create          :
                title         : "Create"
                style         : "modal-clean-green"
                type          : "submit"
                loader        :
                  color       : "#444444"
                  diameter    : 12
                callback      : =>
                  form = @modalTabs.forms["Create New Database"]
                  @dbController.addDatabase form.getFormData(), =>
                    form.buttons.Create.hideLoader()
            fields            :
              dbType          :
                label         : "Type"
                itemClass     : KDSelectBox
                type          : "select"
                name          : "dbType"
                defaultValue  : "mysql"
                selectOptions : [
                  { title : "MySql",    value : "mysql" }
                  { title : "Mongo",    value : "mongo" }
                ]
              dbKind          :
                label         : "Kind"
                itemClass     : KDSelectBox
                type          : "select"
                name          : "dbKind"
                defaultValue  : "free"
                selectOptions : [
                  { title : "Free Database for Development", value : "free" }
                ]
              Information     :
                type          : 'hidden'
                cssClass      : 'database-list'
          "Current Databases" :
            fields            :
              Instances       :
                type          : 'hidden'
                cssClass      : 'database-list'
            buttons           :
              Refresh         :
                style         : "modal-clean-gray"
                type          : 'submit'
                loader        :
                  color       : "#444444"
                  diameter    : 12
                callback      : =>
                  form = @modalTabs.forms["Current Databases"]
                  @dbController.loadItems =>
                    form.buttons.Refresh.hideLoader()

    super options, data

    @dbController = new AccountDatabaseListController
      itemClass : DatabaseListItem

    dbList = @dbController.getListView()
    dbList.on "ListUpdated", => @setPositions()

    dbListForm = @modalTabs.forms["Current Databases"]
    dbListForm.fields.Instances.addSubView @dbController.getView()

    @modalTabs.panes[0].on "KDTabPaneInactive", => @setPositions()
    @modalTabs.panes[0].on "KDTabPaneActive", => @setPositions()

    dbCreateForm = @modalTabs.forms["Create New Database"]

    @dbController.on "DatabaseAdded", (data)=>

      @databaseAdded(data)

      dbCreateForm.inputs.dbType.makeDisabled()
      dbCreateForm.inputs.dbKind.makeDisabled()
      @newDBCreatedWidget?.destroy?()

      dbCreateForm.fields.Information.addSubView \
        @newDBCreatedWidget = new NewDBCreatedWidget {}, data

      dbCreateForm.buttons.Create.setTitle "Ok, got it"

      dbCreateForm.buttons.Create.setClass "modal-clean-gray"
      dbCreateForm.buttons.Create.unsetClass "modal-clean-green"

      dbCreateForm.buttons.Create.setCallback =>
        @newDBCreatedWidget.unsetClass 'ready'

        dbCreateForm.inputs.dbType.makeEnabled()
        dbCreateForm.inputs.dbKind.makeEnabled()

        dbCreateForm.buttons.Create.setTitle "Create"
        dbCreateForm.buttons.Create.setClass "modal-clean-green"
        dbCreateForm.buttons.Create.unsetClass "modal-clean-gray"
        dbCreateForm.buttons.Create.hideLoader()

        dbCreateForm.buttons.Create.setCallback =>
          form = @modalTabs.forms["Create New Database"]
          @dbController.addDatabase form.getFormData(), =>
            form.buttons.Create.hideLoader()

        KD.utils.wait 300, => @setPositions()

      @dbController.loadItems()

  ## LOG: Duplicate entries in database.
  databaseAdded: (data)->
    if @databases[data.dbName]
      KD.logToExternal msg:"duplicate database", dbName:data.dbName
    else
      @databases[data.dbName] = true
  ##

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

  loadView:->

    super
    list = @getListView()
    @loadItems()

    list.on "DeleteDatabaseSubmitted", (listItem)=> @deleteDatabase listItem
    list.on "UpdateDatabaseSubmitted", (listItem, password)=>
      @updateDatabase listItem, password

    list.on "HideAllWidgets", =>
      for item in @itemsOrdered
        item.deleteWidget?.destroy?()
        item.editWidget?.destroy?()
        delete item.deleteWidget
        delete item.editWidget

    @on "DatabaseUpdated", (listItem)=>
      listItem.changePassword.hideLoader()
      @emit "ListUpdated"
      list.emit "HideAllWidgets"

    @on "DatabaseDeleted", (listItem)=>
      list.removeItem listItem
      if @itemsOrdered.length == 0
        @addCustomItem "You don't have any database to show."

      @emit "ListUpdated"

  addCustomItem:(message)->
    @removeAllItems()
    @customItem?.destroy()
    @scrollView.addSubView @customItem = new KDCustomHTMLView
      cssClass : "no-item-found"
      partial  : message

  loadItems:(callback)->

    @removeAllItems()
    @customItem?.destroy()
    @showLazyLoader no

    dbTypes = ['mysql', 'mongo']
    responses = []
    responseToWait = dbTypes.length

    for dbtype in dbTypes
      @talkToKite
        method : @commands[dbtype].fetch
      , KD.utils.getTimedOutCallback (err, dbs)=>
        responseToWait--
        if dbs?.length > 0
          responses = responses.concat dbs
        if responseToWait == 0
          @hideLazyLoader()
          if responses.length > 0
            @instantiateListItems responses
          else
            @addCustomItem """You don't have any databases.
                              Why don't you create a new one?"""
          callback?()
      , =>
        @hideLazyLoader()
        @addCustomItem """It seems there is something wrong with
                          database provider. Please try again later."""
        callback?()
      , 10000

  deleteDatabase:(listItem)->
    data       = listItem.getData()
    @talkToKite
      method   : @commands[data.dbType].remove
      withArgs :
        dbUser : data.dbUser
        dbName : data.dbName
    , (err, response)=>
      if err
        @notify "An error occured, try again later!", "error"
      else
        @notify "Database deleted!", "succes"
        @emit "DatabaseDeleted", listItem

  updateDatabase:(listItem, password)->

    data = listItem.getData()

    @talkToKite
      method        : @commands[data.dbType].update
      withArgs      :
        dbUser      : data.dbUser
        newPassword : password
    , (err, response)=>
      if err
        @notify "An error occured, try again later!", "error"
      else
        @notify "Database updated!", "succes"
        @emit "DatabaseUpdated", listItem

  addDatabase:(formData, callback)->
    {dbType} = formData

    {nickname} = KD.whoami().profile
    dbUser = dbName = __utils.generatePassword 15-nickname.length, yes
    dbPass = __utils.generatePassword 40, no

    @talkToKite
      method    : @commands[dbType].create
      withArgs  : {dbName, dbUser, dbPass}
    , (err, response)=>
      if err
        @notify err.message or "An error occured, try again later!", "error"
      else
        @notify "Database created!", "succes"
        @emit "DatabaseAdded", response
      callback?()

  talkToKite:(options, callback)->

    KD.getSingleton("kiteController").run
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

class DatabaseListItem extends KDListItemView

  constructor:(options = {},data)->

    options.cssClass = 'database-listitem'

    super options, data

    listView = @getDelegate()
    @changePassword = new KDButtonView
      style       : "clean-gray"
      icon        : yes
      iconOnly    : yes
      iconClass   : "edit"
      tooltip     :
        title     : "Change Password"
        placement : "left"
      loader      :
        color     : "#666"
        diameter  : 16
      callback    : =>
        @changePassword.hideLoader()
        hasWidget = @editWidget?
        listView.emit "HideAllWidgets"
        unless hasWidget
          @addSubView @editWidget = new InlineEditWidget @

    @deleteDatabase = new KDButtonView
      style       : "clean-gray"
      icon        : yes
      iconOnly    : yes
      iconClass   : "delete"
      tooltip     :
        title     : "Delete database"
        placement : "right"
      loader      :
        color     : "#666"
        diameter  : 16
      callback    : =>
        @deleteDatabase.hideLoader()
        hasWidget = @deleteWidget?
        listView.emit "HideAllWidgets"
        unless hasWidget
          @addSubView @deleteWidget = new InlineDeleteWidget @

  viewAppended:->
    @setTemplate @pistachio()
    @template.update()

  pistachio:->
    {dbType} = @getData()
    """
    <span class='database-type #{dbType}'>{{#(dbType)}}</span>
    <div class='database-details'>
      <h4>{{#(dbUser)}}</h4>
      <cite>{{#(dbHost)}}</cite>
      {{> @changePassword}}
      {{> @deleteDatabase}}
    </div>
    """

class InlineDeleteWidget extends JView

  constructor:(item)->
    options =
      cssClass : 'inline-delete-widget'
    data = item.getData()

    super options, data

    @deleteButton = new KDButtonView
      title    : "Delete"
      cssClass : "modal-clean-red"
      callback : =>
        @deleteButton.disable()
        @cancelButton.disable()
        item.deleteDatabase.showLoader()
        item.deleteDatabase.disable()
        item.getDelegate().emit "DeleteDatabaseSubmitted", item

    @cancelButton = new KDButtonView
      title    : "Cancel"
      cssClass : "modal-clean-gray"
      callback : => item.getDelegate().emit "HideAllWidgets"

    KD.utils.wait => @setClass 'ready'

  pistachio:->
    """
      <p>Are you sure want to delete <strong>{{#(dbName)}}</strong>?</p>
      {{> @cancelButton}} {{> @deleteButton}}
    """

class InlineEditWidget extends JView

  constructor:(item)->
    options =
      cssClass : 'inline-edit-widget'
    data = item.getData()

    super options, data

    @newPassword = new KDInputView
      type        : "password"
      placeholder : "Type your new password here..."

    @updateButton = new KDButtonView
      title    : "Update"
      cssClass : "modal-clean-green"
      callback : =>
        @updateButton.disable()
        @cancelButton.disable()
        item.changePassword.showLoader()
        item.getDelegate().emit \
          "UpdateDatabaseSubmitted", item, @newPassword.getValue()

    @cancelButton = new KDButtonView
      title    : "Cancel"
      cssClass : "modal-clean-gray"
      callback : => item.getDelegate().emit "HideAllWidgets"

    KD.utils.wait => @setClass 'ready'

  pistachio:->
    """
      {{> @newPassword}} {{> @cancelButton}} {{> @updateButton}}
    """

class NewDBCreatedWidget extends KDView

  constructor:(options = {}, data)->

    # We can provide a connection string for mongo dbs
    # But I couldn't find a proper solution to put it in view
    #
    # connectionString = ''
    # if data.dbType is 'mongo'
    #   connectionString = \
    #     "mongodb://#{data.dbUser}:#{data.dbPass}@#{data.dbHost}/#{data.dbName}"
    #   connectionString = \
    #     "<p><label>Connection String:</label> <b>#{connectionString}</b></p>"

    options.cssClass = "modal-hint"
    options.partial  = """
      <p>Your new <cite>#{data.dbType}</cite> database has just been created!</p>
      <p><label>Host:</label> <i>#{data.dbHost}</i></p>
      <p><label>Name:</label> <i>#{data.dbName}</i></p>
      <p><label>User:</label> <i>#{data.dbUser}</i></p>
      <p><label>Password:</label> <b>#{data.dbPass}</b></p>
      <p>
         This is an one time password, please keep it somewhere safe
         you won't be able to reveal it again, but you'll always be
         able to reset it from here.
      </p>
      """

    super

    KD.utils.wait => @setClass 'ready'
