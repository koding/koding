class AccountMountListController extends KDListViewController

  mapBongoInstanceToView = (mount) ->
    mount.type ?= mount.constructor.name
    item =
      title         : mount.title ? mount.hostname
      type          : (mount.type.replace "JMount","").toLowerCase()
      hostname      : mount.hostname
      username      : mount.username
      password      : mount.password
      port          : mount.port
      accessibleTo  : []
      jmount        : mount

    return item

  constructor:->
    super
    @account = KD.whoami()
    list = @getListView()

    list.registerListener
      KDEventTypes  : "UpdateFormSubmitted"
      listener      : @
      callback      : (pubInst,{listItem, formData})=>
        @updateMount listItem, formData

  loadView:->
    super

    @loadItems()

    # @getView().parent.addSubView addButton = new KDButtonView
    #   style     : "clean-gray account-header-button"
    #   title     : ""
    #   icon      : yes
    #   iconOnly  : yes
    #   iconClass : "plus"
    #   callback  : ()=>
    #     @getListView().showAddEditModal null

  loadItems:(callback)->
    items = [
      { title : "Mounts are coming soon" }
    ]
    @instantiateListItems items
    # @account.fetchMounts (err,mounts)=>
    #   items ?= []
    #   for mount in mounts
    #     item = mapBongoInstanceToView mount
    #     items.push item
    #   @instantiateListItems items

  updateMount:(listItem, formData)=>
    f = formData

    switch f.operation
      when "delete"
        jmount = listItem.getData().jmount
        jmount.remove (err)=>
          @getListView().removeListItem @getListView()._listItemToBeUpdated
      when "update"
        jmount = listItem.getData().jmount

        # jmount.title     = f.title
        jmount.hostname  = f.hostname
        jmount.username  = f.username
        jmount.password  = f.password
        # jmount.port      = f.port

        jmount.update (err)=>
          if err
            new KDNotificationView
              type : "growl"
              title : "Mount Update Failed. #{err}"
              duration : 1000
          else
            @getListView()._listItemToBeUpdated.emit "mountUpdated",jmount
            new KDNotificationView
              type : "growl"
              title : "Mount Updated!"
              duration : 1000


      when "add"
        switch f.type
          when "ftp"
            jm = new KD.remote.api.JMountFTP
              title         : f.title ? f.hostname
              hostname      : f.hostname
              username      : f.username
              password      : f.password
              port          : f.port
          when "sftp"
            jm = new KD.remote.api.JMountSFTP
              title         : f.title ? f.hostname
              hostname      : f.hostname
              username      : f.username
              password      : f.password
              port          : f.port
          # when "s3"
          #   jm = new KD.remote.api.JMountS3
          #     title         : f.title ? f.hostname
          #     accessKeyId   : f.accessKey
          #     secret        : f.secret
          # when "webdav"
          #   jm = new KD.remote.api.JMountWebDav
          #     title         : f.title ? f.hostname
          #     hostname      : f.hostname
          #     username      : f.username
          #     password      : f.password
          #     port          : f.port

        jm.save (err)=>
          if err
            new KDNotificationView
              type : "growl"
              title : "Mount Add Failed. #{err}"
              duration : 1000
          else
            @emit "mountAdded",jm
            new KDNotificationView
              type : "growl"
              title : "Mount Added!"
              duration : 1000


        # jm.save()
    @getListView().destroyModal()


class AccountMountList extends KDListView

  mapBongoInstanceToView = (mount) ->
    mount.type ?= mount.constructor.name
    item =
      title         : mount.title ? mount.hostname
      type          : (mount.type.replace "JMount","").toLowerCase()
      hostname      : mount.hostname
      username      : mount.username
      password      : mount.password
      port          : mount.port
      accessibleTo  : []
      jmount        : mount

    return item

  constructor:(options,data)->
    options = $.extend
      tagName       : "ul"
      itemClass  : AccountMountListItem
    ,options
    super options,data
    @account = KD.whoami()

    @on "mountAdded",(mount)=>
      log "mountAdded",mount
      newItemData = mapBongoInstanceToView mount
      @addItemView new AccountMountListItem delegate:@,newItemData

    @on "ShowAddEditModal",(data,item)  => @showAddEditModal data,item

  showAddEditModal:(data,listItem)=>

    @_listItemToBeUpdated = listItem

    modal = @modal = new KDModalView
      title     : "Add a mount"
      content   : ""
      overlay   : yes
      cssClass  : "new-kdmodal"
      width     : 500
      height    : "auto"
      buttons   : yes

    formData = _fe = ()->
      type :
        label : new KDLabelView
          title : "Select Type:"
        input : new KDSelectBox
          type        : "select"
          name        : "type"
          defaultValue: if data then data.type else "ftp"
          selectOptions : [
            # { title : "Select mount type...", value : "none" }
            { title : "FTP",                  value : "ftp" }
            { title : "SFTP",                 value : "sftp" }
            # { title : "S3",                   value : "s3" }
            # { title : "WebDAV",               value : "webdav" }
            # { title : "Dropbox",              value : "dropbox" }
          ]

      # title :
      #   label : new KDLabelView
      #     title : "Title:"
      #   input: new KDInputView
      #     name        : "title"
      #     placeholder : "give it a name if you like..."
      #     defaultValue: data.title if data

      hostname :
        label :  new KDLabelView
          title : "Hostname:"
        input : new KDInputView
          name        : "hostname"
          placeholder : "your host address..."
          defaultValue: data.hostname if data

      username :
        label : new KDLabelView
          title : "Username:"
        input : new KDInputView
          name        : "username"
          placeholder : "username..."
          defaultValue: data.username if data

      password :
        label: new KDLabelView
          title : "Password:"
        input : new KDInputView
          type        : "password"
          name        : "password"
          placeholder : "password..."
          defaultValue: data.password if data

      # port :
      #   label : new KDLabelView
      #     title : "Port number:"
      #   input : new KDInputView
      #     name        : "port"
      #     placeholder : "port..."
      #     defaultValue: data.port if data

      # accessKey :
      #   label : new KDLabelView
      #     title : "Access Key:"
      #   input : new KDInputView
      #     name        : "accessKey"
      #     placeholder : "AWS access key..."
      #     defaultValue: data.accessKey if data

      # secret :
      #   label : new KDLabelView
      #     title : "Secret Key:"
      #   input : new KDInputView
      #     type        : "password"
      #     name        : "secret"
      #     placeholder : "AWS Secret"
      #     defaultValue: data.secret if data

    createForm = (items)=>

      attachListenerToTypeSelection = (item)->
        item.on "change",(event,value)->
          # log value,s3Form,form
          switch value
            when "ftp","sftp"#,"webdav"
              lines.hostname.show()
              lines.username.show()
              lines.password.show()
              # lines.port.show()
              # lines.accessKey.hide()
              # lines.secret.hide()
            # when "none"
            #   lines.hostname.hide()
            #   lines.username.hide()
            #   lines.password.hide()

            # when "s3"
            #   lines.accessKey.show()
            #   lines.secret.show()
            #   lines.hostname.hide()
            #   lines.username.hide()
            #   lines.password.hide()
            #   lines.port.hide()

      lines = {}
      form = new KDFormView
        cssClass : "clearfix"
        callback : (formData)=>
          @propagateEvent KDEventType : "UpdateFormSubmitted", {listItem, formData}

      height =  items.length*75

      for own item in items
        lines[item] = new KDView cssClass : "modalformline"
        lines[item].addSubView label = _fe()[item].label
        lines[item].addSubView input = _fe()[item].input
        attachListenerToTypeSelection input if item is "type"
        form.addSubView lines[item]

      return {form,lines}


    # {form,lines} = createForm ["type","title","hostname","username","password","port","accessKey","secret"]
    {form,lines} = createForm ["type","hostname","username","password"]
    # lines.accessKey.hide()
    # lines.secret.hide()
    modal.addSubView form
    # modal.setHeight 450

    if data
      form.addCustomData "operation","update"
      modal.createButton "Update", style : "modal-clean-gray", callback : form.submit
      modal.createButton "Delete", style : "modal-clean-red", callback : (event)=>
        form.addCustomData "operation","delete"
        form.submit(event)
    else
      form.addCustomData "operation","add"
      modal.createButton "Add", style : "modal-clean-gray", callback : form.submit

    modal.createButton "cancel",style : "modal-cancel", callback : @destroyModal
    modal.addSubView helpBox = new HelpBox, ".kdmodal-buttons"

  destroyModal:=>
    @modal.destroy()


class AccountMountListItem extends KDListItemView
  constructor:->
    super

    # mount = @getData().jmount
    # mount.on "update",()=>
    #   data = mapBongoInstanceToView mount
    #   @setData data
    #   @updatePartial @partial data

  click:(event)->
    # if $(event.target).is ".action-link" then @getDelegate().emit "ShowAddEditModal",@getData(),@

  setDomElement:(cssClass)->
    @domElement = $ "<li class='kdview clearfix #{cssClass}'></li>"

  partial:(data)->
    """
      <span class='darkText'>#{data.title}</span>
    """
  # partial:(data)->
  #   accessibleClass = if data.accessibleTo?.length > 0 then "class='lightText'" else "class='darkText'"
  #   """
  #     <div class='labelish'>
  #       <span class='mount-title'>#{data.title or data.hostname}</span>
  #     </div>
  #     <div class='swappableish swappable-wrapper posstatic'>
  #       <span class='ttag #{data.type}'>#{data.type}</span>
  #       <span class='darkText'>accessible to</span>
  #       <span #{accessibleClass}>#{(data.accessibleTo or []).length} environments</span>
  #     </div>
  #     <a href='#' class='action-link'>Edit</a>
  #   """
