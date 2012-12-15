class ManageRemotesModal extends KDModalViewWithForms

  constructor:(options = {}, data)->

    options =
      title                   : "Manage Remotes"
      content                 : ""
      overlay                 : yes
      width                   : 500
      height                  : "auto"
      cssClass                : "remotes-modal"
      tabs                    :
        navigable             : yes
        goToNextFormOnSubmit  : no
        forms                 :
          "Create a new Remote" :
            fields            :
              remotetype      :
                label         : "Remote type"
                itemClass     : KDSelectBox
                defaultValue  : "ftp"
                selectOptions : [
                  { title : "FTP",  value : "ftp" }
                  # { title : "SFTP", value : "sftp" }
                ]
                # callback      : -> log arguments
              remotehost      :
                label         : "Hostname"
                placeholder   : "provide remote address without protocol"
                validate      :
                  rules       :
                    required  : yes
                   messages   :
                    required  : "Please provide at least remote host address..."
              remoteuser      :
                label         : "Username"
                placeholder   : "leave empty if anonymous"
              remotepass      :
                label         : "Password"
                placeholder   : "leave empty if anonymous"
                type          : "password"
              storepass       :
                label         : "Save Password"
                itemClass     : KDYesNoSwitch
                callback      : (state)=>
                  if state then @savePasswordWarning.show()
                  else @savePasswordWarning.hide()
            buttons           :
              "Create & Mount":
                style         : "modal-clean-green"
                type          : 'submit'
                loader        :
                  color       : "#444444"
                  diameter    : 12
                callback      : -> @hideLoader()
            callback          : =>
              form = @modalTabs.forms["Create a new Remote"]
              form.buttons["Create & Mount"].showLoader()
              @showMessage "Creating new mount..."
              @createNewRemote form.getFormData(), ->
                form.buttons["Create & Mount"].hideLoader()
          "Current Remotes"   :
            fields            :
              Mounts          :
                type          : 'hidden'
                cssClass      : 'mount-list'
            buttons           :
              Refresh         :
                title         : "Refresh"
                style         : "modal-clean-gray"
                loader        :
                  color       : "#444444"
                  diameter    : 12
                callback      : =>
                  form = @modalTabs.forms['Current Remotes']
                  @refreshMountList ->
                    form.buttons.Refresh.hideLoader()

    super options, data

    @kc = KD.getSingleton 'kiteController'

    newRemoteForm = @modalTabs.forms['Create a new Remote']
    mountsForm    = @modalTabs.forms['Current Remotes']

    @mountController = new KDListViewController
      itemClass   : RemoteListItem

    mountList = @mountController.getListView()
    mountList.on "MountRemote",   @mountRemote
    mountList.on "DeleteRemote",  @removeMount
    mountList.on "UmountRemote",  @umountRemote
    mountList.on "RefreshFolder", @refreshRemoteDrives

    mountsForm.fields.Mounts.addSubView @mountController.getView()

    @savePasswordWarning = new KDView
      cssClass  : "modal-hint"
      partial   : """
                   <p>For automatic mounts you can save your password on Koding Servers as encrypted.
                   If you don't prefer to save passwords Koding will ask you each time when it tries
                   to mount your remote drive.</p>
                   <p><cite>* We take security seriously, but its still <strong>not recommended</strong>
                   to save passwords.</cite></p>
                  """
    @savePasswordWarning.hide()

    @detailsHint = new KDView
      cssClass  : 'details-hint'
      partial   : ''
      click     : (event)->
        @hide() if $(event.target).is "span.close-icon"

    @modalTabs.addSubView @detailsHint #, null, yes
    @modalTabs.addSubView @savePasswordWarning #, null, yes

    @modalTabs.panes[0].on "KDTabPaneInactive", =>
      @hideMessages()
      @savePasswordWarning.hide()

    @modalTabs.panes[0].on "KDTabPaneActive", =>
      @hideMessages()
      @savePasswordWarning.show() if newRemoteForm.inputs.storepass.getValue()

    @statusText1 = new KDView
      cssClass  : "status-hint fl"
      click     : (event)=>
        if $(event.target).is "span"
          @detailsHint.show()
          @statusText1.hide()

    @statusText2 = new KDView
      cssClass  : "status-hint fl"
      click     : (event)=>
        if $(event.target).is "span"
          @detailsHint.show()
          @statusText2.hide()

    @modalTabs.panes[0].form.buttonField.addSubView @statusText1, null, yes
    @modalTabs.panes[1].form.buttonField.addSubView @statusText2, null, yes

    @hideMessages()
    @refreshMountList()

  hideMessages:->
    @detailsHint.hide()
    @statusText1.hide()
    @statusText2.hide()

  showMessage:(message, details = '')->
    message = "<strong>An error occured!</strong> <span>Click</span> here for details." unless message
    @savePasswordWarning.hide()
    @statusText1.updatePartial message
    @statusText1.show()
    @statusText2.updatePartial message
    @statusText2.show()
    @detailsHint.updatePartial "<p>#{details}</p><span class='close-icon'></span>"

  refreshMountList:(callback)->
    @mountController.removeAllItems()
    @noRemoteFoundItem?.destroy()
    @kc.run
      method : 'readMountInfo'
    , (err, mounts)=>
      log mounts
      if not err and mounts?.length == 0
        @mountController.scrollView.addSubView @noRemoteFoundItem = new KDCustomHTMLView
          cssClass: "no-remote-found"
          partial : "There is no remote drive attached to your Virtual Environment."
      else
        @mountController.instantiateListItems mounts unless err
      error err if err
      callback?()

  mountRemote:(mount, callback)=>
    {remotehost, haspass, remotepass, remoteuser} = mount
    args = {remotehost, remoteuser}
    args.remotepass = remotepass unless haspass
    log args
    @hideMessages()
    @kc.run
      method   : 'mountDrive'
      withArgs : args
    , (err, res)=>
      log err, res
      if err
        @showMessage null, err
      else
        @refreshRemoteDrives remotehost
      callback? err

  umountRemote:({remotehost, remoteuser, mountpoint}, callback)=>
    @hideMessages()
    @kc.run
      method   : 'umountDrive'
      withArgs : {remotehost, remoteuser, mountpoint}
    , (err, res)=>
      log err, res
      if err
        @showMessage null, err
      else
        @refreshRemoteDrives()
      callback? err

  createNewRemote:(formData, callback)->
    @detailsHint.hide()
    @kc.run
      method   : 'mountFtpDrive'
      withArgs : formData
    , (err, res)=>
      callback?()
      if err
        @showMessage null, err
      else
        @refreshMountList =>
          @modalTabs.showNextPane()
          @hideMessages
          @refreshRemoteDrives formData.remotehost
          new KDNotificationView
            title    : "New remote created sucessfully."
            type     : "mini"
            cssClass : "success"

          @modalTabs.forms['Create a new Remote'].reset()
      log arguments

  removeMount:({remoteuser, remotehost, mountpoint})=>
    @kc.run
      method       : 'removeMount'
      withArgs     : {remoteuser, remotehost, mountpoint}
    , (err)=>
      @refreshRemoteDrives()
      @refreshMountList()
      new KDNotificationView
        title    : "Remote Drive removed sucessfully"
        type     : "mini"
        cssClass : "success"

  refreshRemoteDrives:(finalPath = '', destroy = no)=>
    {nickname} = KD.whoami().profile
    tc = KD.getSingleton("finderController").treeController
    tc.navigateTo "/Users/#{nickname}/RemoteDrives", =>
      if finalPath
        tc.refreshFolder tc.nodes["/Users/#{nickname}/RemoteDrives/#{finalPath}"], =>
          tc.selectNode tc.nodes["/Users/#{nickname}/RemoteDrives/#{finalPath}"]
          @destroy() if destroy
      else
        @destroy() if destroy

class RemoteListItem extends KDListItemView

  constructor:(options = {},data)->

    options.cssClass = 'remote-listitem'

    @mountpoint = data.mountpoint
    data.mountpoint = 'Not mounted' unless data.mounted

    super options, data

    @mountToggle = new KDToggleButton
      style        : "kdwhitebtn mount-toggle"
      loader       :
        color      : "#666"
        diameter   : 16
      states       : [
        "Mount", (callback)=>
          unless data.haspass
            @mountToggle.hideLoader()
            new AskForPassword "Password required to mount #{data.remotehost}", (password)=>
              data.remotepass = password
              @mountToggle.showLoader()
              @changeMountState {state : 'mount', data}, callback
          else
            @changeMountState {state : 'mount', data}, callback
        "Unmount", (callback)=>
          @changeMountState {state : 'umount', data}, callback
      ]
      defaultState : if data.mounted then "Unmount" else "Mount"
    , data

    @deleteRemote = new KDButtonView
      style       : "clean-gray delete-remote-button"
      icon        : yes
      iconOnly    : yes
      iconClass   : "delete"
      tooltip     :
        title     : "Delete remote"
        placement : "right"
      loader      :
        color     : "#666"
        diameter  : 16
      callback    : =>
        @deleteRemote.hideLoader()
        modal = new KDModalView
          title          : "Delete remote?"
          content        : "<div class='modalformline'>Are you sure you want to delete this remote drive?</div>"
          height         : "auto"
          overlay        : yes
          buttons        :
            Delete       :
              style      : "modal-clean-red"
              callback   : =>
                @mountToggle.disable()
                @deleteRemote.showLoader()
                @getDelegate().emit "DeleteRemote",
                  mountpoint : @mountpoint
                  remotehost : data.remotehost
                  remoteuser : data.remoteuser
                modal.destroy()

  viewAppended:->
    @setTemplate @pistachio()
    @template.update()

  pistachio:->

    """
    <span class='remote-type'>{{#(remotetype)}}</span>
    <div class='remote-details'>
      <h3>{{#(remoteuser)}}@{{#(remotehost)}}</h3>
      <cite>{{#(mountpoint)}}</cite>
      {{> @mountToggle}}
      {{> @deleteRemote}}
    </div>
    """

  changeMountState:(options, callback)->
    {state, data} = options
    signal = if state is 'mount' then "MountRemote" else "UmountRemote"
    @deleteRemote.disable()
    @getDelegate().emit signal, data, (err)=>
      @mountToggle.hideLoader()
      if not err
        delete data.remotepass
        data.mountpoint = if state is 'mount' then @mountpoint else 'Not mounted'
        data.mounted = state is 'mount'
        @setData data
        @template.update()
      @deleteRemote.enable()
      callback? err

  click:(event)->
    {mounted, remotehost} = @getData()
    @getDelegate().emit "RefreshFolder", @getData().remotehost, yes if mounted

class KDYesNoSwitch extends KDOnOffSwitch
  constructor:(options = {}, data)->
    options.title  = ''
    options.labels = ['YES', 'NO']
    super

class AskForPassword extends KDModalViewWithForms

  constructor:(message, callback)->

    options =
      title                   : "Password Required"
      content                 : "<div class='modalformline'>#{message}</div>"
      overlay                 : yes
      width                   : 500
      height                  : "auto"
      # cssClass                : "remotes-modal"
      tabs                    :
        navigable             : no
        goToNextFormOnSubmit  : no
        forms                 :
          Password            :
            fields            :
              password        :
                label         : "Password"
                placeholder   : "enter password or leave it blank"
                type          : "password"
                # validate      :
                #   rules       :
                #     required  : yes
                #    messages   :
                #     required  : "Password required"
            buttons           :
              Continue        :
                style         : "modal-clean-green"
                type          : 'submit'
                loader        :
                  color       : "#444444"
                  diameter    : 12
            callback          : =>
              form = @modalTabs.forms.Password
              callback form.inputs.password.getValue()
              @destroy()

    super options
