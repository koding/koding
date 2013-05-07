class AdminModal extends KDModalViewWithForms

  constructor : (options = {}, data) ->

    options =
      title                   : "Admin Panel"
      content                 : "<div class='modalformline'>With great power comes great responsibility. ~ Stan Lee</div>"
      overlay                 : yes
      width                   : 600
      height                  : "auto"
      cssClass                : "admin-kdmodal"
      tabs                    :
        navigable             : yes
        goToNextFormOnSubmit  : no
        forms                 :
          "User Details"      :
            buttons           :
              Update          :
                title         : "Update"
                style         : "modal-clean-gray"
                loader        :
                  color       : "#444444"
                  diameter    : 12
                callback      : =>
                  {inputs, buttons} = @modalTabs.forms["User Details"]
                  accounts = @userController.getSelectedItemData()
                  if accounts.length > 0
                    account  = accounts[0]
                    flags    = [flag.trim() for flag in inputs.Flags.getValue().split(",")][0]
                    account.updateFlags flags, (err)->
                      error err if err
                      KD.remote.api.JInvitation.grantInvitesFromClient
                        username : account.profile.nickname
                        quota    : +inputs.Invites.getValue()
                      , (err)=>
                        console.error err if err
                        new KDNotificationView {title: "Done!"}
                        buttons.Update.hideLoader()
                  else
                    new KDNotificationView {title : "Select a user first"}
            fields            :
              Username        :
                label         : "Dear User"
                type          : "hidden"
                nextElement   :
                  userWrapper :
                    itemClass : KDView
                    cssClass  : "completed-items"
              Flags           :
                label         : "Flags"
                placeholder   : "no flags assigned"
              Invites         :
                label         : "Grant Invites"
                type          : "text"
                placeholder   : "number of invites to add"
                validate      :
                  rules       :
                    regExp    : /\d+/i
                  messages    :
                    regExp    : "numbers only please"
              Impersonate     :
                label         : "Switch to User"
                itemClass     : KDButtonView
                title         : "Impersonate"
                callback      : =>
                  modal = new KDModalView
                    title          : "Switch to this user?"
                    content        : "<div class='modalformline'>This action will reload Koding and log you in with this user.</div>"
                    height         : "auto"
                    overlay        : yes
                    buttons        :
                      Impersonate  :
                        style      : "modal-clean-green"
                        loader     :
                          color    : "#FFF"
                          diameter : 16
                        callback   : =>
                          accounts = @userController.getSelectedItemData()
                          unless accounts.length is 0
                            KD.impersonate accounts[0].profile.nickname, =>
                              modal.destroy()
                          else
                            modal.destroy()
          "Send Beta Invites" :
            buttons           :
              "Send Invites"  :
                title         : "Send Invites"
                style         : "modal-clean-gray"
                loader        :
                  color       : "#444444"
                  diameter    : 12
                callback      : =>
                  {inputs, buttons} = @modalTabs.forms["Send Beta Invites"]
                  inputs.statusInfo.updatePartial 'Working on it...'
                  KD.remote.api.JInvitation.sendBetaInviteFromClient
                    batch     : +inputs.Count.getValue()
                  , (err, res)->
                    buttons['Send Invites'].hideLoader()
                    inputs.statusInfo.updatePartial res
                    console.log res, err
            fields            :
              Information     :
                label         : "Current state"
                type          : "hidden"
                nextElement   :
                  currentState:
                    itemClass : KDView
                    partial   : 'Loading...'
                    cssClass  : 'information-line'
              Count           :
                label         : "# of Invites"
                type          : "text"
                defaultValue  : 10
                placeholder   : "how many users do you want to Invite?"
                validate      :
                  rules       :
                    regExp    : /\d+/i
                  messages    :
                    regExp    : "numbers only please"
              Status          :
                label         : "Server response"
                type          : "hidden"
                nextElement   :
                  statusInfo  :
                    itemClass : KDView
                    partial   : '...'
                    cssClass  : 'information-line'

          "Migrate Kodingen Users" :
            buttons           :
              Migrate         :
                title         : "Migrate"
                style         : "modal-clean-gray"
                loader        :
                  color       : "#444444"
                  diameter    : 12
                callback      : =>
                  {inputs, buttons} = @modalTabs.forms["Migrate Kodingen Users"]
                  inputs.statusInfo.updatePartial 'Working on it...'
                  KD.remote.api.JOldUser.__migrateKodingenUsers
                    limit     : +inputs.Count.getValue()
                    delay     : +inputs.Delay.getValue()
                  , (err, res)->
                    buttons.Migrate.hideLoader()
                    inputs.statusInfo.updatePartial res
                    console.log res, err
              Stop            :
                title         : "Stop"
                style         : "modal-clean-red"
                loader        :
                  color       : "#444444"
                  diameter    : 12
                callback      : =>
                  form = @modalTabs.forms["Migrate Kodingen Users"]
                  form.inputs.statusInfo.updatePartial 'Trying to stop...'
                  KD.remote.api.JOldUser.__stopMigrate (err, res)->
                    form.buttons.Stop.hideLoader()
                    form.buttons.Migrate.hideLoader()
                    form.inputs.statusInfo.updatePartial res
                    console.log res, err
            fields            :
              Information     :
                label         : "Current state"
                type          : "hidden"
                nextElement   :
                  currentState:
                    itemClass : KDView
                    partial   : 'Loading...'
                    cssClass  : 'information-line'
              Count           :
                label         : "# of Migrate"
                type          : "text"
                defaultValue  : 10
                placeholder   : "how many users do you want to Migrate?"
                validate      :
                  rules       :
                    regExp    : /\d+/i
                  messages    :
                    regExp    : "numbers only please"
              Delay           :
                label         : "Delay (in sec.)"
                type          : "text"
                defaultValue  : 60
                placeholder   : "how many seconds do you need before create new user?"
                validate      :
                  rules       :
                    regExp    : /\d+/i
                  messages    :
                    regExp    : "numbers only please"
              Status          :
                label         : "Server response"
                type          : "hidden"
                nextElement   :
                  statusInfo  :
                    itemClass : KDView
                    partial   : '...'
                    cssClass  : 'information-line'

          "Broadcast Message" :
            buttons           :
              "Broadcast Message"  :
                title         : "Broadcast"
                style         : "modal-clean-gray"
                loader        :
                  color       : "#444444"
                  diameter    : 12

                callback      : (event)=>
                  {inputs, buttons} = @modalTabs.forms["Broadcast Message"]

                  KD.remote.api.JSystemStatus.create
                    scheduledAt : Date.now()+inputs.Duration.getValue()*1000
                    title     : inputs.Title.getValue()
                    content   : inputs.Description.getValue()
                    type      : inputs.Type.getValue()
                  , ->
                    buttons["Broadcast"].hideLoader()

              "Cancel Restart":
                title         : "Cancel Restart"
                style         : "modal-clean-gray"
                loader        :
                  color       : "#444444"
                  diameter    : 12

                callback      : (event)=>
                  {inputs, buttons} = @modalTabs.forms["Broadcast Message"]
                  KD.remote.api.JSystemStatus.stopCurrentSystemStatus (err,res)->
                    buttons["Cancel Restart"].hideLoader()

            fields            :
              Presets         :
                label         : 'Use Preset'
                type          : 'select'
                cssClass      : 'preset-select'
                selectOptions :
                  [
                    { title   : "No preset selected",  value : "none"   }
                    { title   : "Shutdown in...",    value : "restart"   }
                    { title   : "Please refresh...",     value : "reload"    }
                  ]
                defaultValue  : 'none'
                change        : =>
                  msgMap      =
                    'none' :
                      title   : ''
                      content : ''
                      duration: 300
                      type    : 'restart'
                    'restart' :
                      title   : 'Shutdown in'
                      content : 'We are upgrading the platform. Please save your work.'
                      duration: 300
                      type    : 'restart'
                    'reload'  :
                      title   : 'Koding was updated. Please refresh!'
                      content : 'Please refresh your browser to be able to use the newest features of Koding.'
                      duration: 10
                      type    : 'reload'

                  {inputs, buttons} = @modalTabs.forms["Broadcast Message"]
                  preset = inputs.Presets.getValue()
                  inputs['Title'].setValue msgMap[preset].title
                  inputs['Description'].setValue msgMap[preset].content
                  inputs['Duration'].setValue msgMap[preset].duration
                  inputs['Type'].setValue msgMap[preset].type
              Title           :
                label         : "Message Title"
                type          : "text"
                placeholder   : "Shutdown in"
                tooltip       :
                  title       : 'When using type "Restart", end title with "in",'+\
                  ' since there will be a timer following the title.'
                  placement   : 'right'
                  direction   : 'center'
                  offset      :
                    top       : 2
                    left      : 0
              Description     :
                label         : "Message Details"
                type          : "text"
                placeholder   : "We are upgrading the platform. Please save your work."
              Duration        :
                label         : "Timer duration"
                type          : "text"
                defaultValue  : 5*60
                tooltip       :
                  title       : 'in seconds'
                  placement   : 'right'
                  direction   : 'center'
                  offset      :
                    top       : 2
                    left      : 0
                placeholder   : "Please enter a reasonable timeout."
              Type            :
                label         : 'Type'
                type          : 'select'
                cssClass      : 'type-select'
                selectOptions :
                  [
                    { title   : "Restart",    value : "restart"   }
                    { title   : "Info Text",  value : "info"  }
                    { title   : "Reload",     value : "reload"    }
                  ]
                defaultValue  : 'restart'
                change        : =>
                  {inputs, buttons} = @modalTabs.forms["Broadcast Message"]
                  type = inputs.Type.getValue()
                  inputs['presetExplanation'].updatePartial switch type
                    when 'restart'
                      'This will show a timer.'
                    else
                      'No timer will be shown.'
                nextElement   :
                  presetExplanation:
                    cssClass  : 'type-explain'
                    itemClass : KDView
                    partial   : 'This will show a timer.'
          "Introduction":
            fields            : {}

    super options, data

    {inputs, buttons} = @modalTabs.forms["Broadcast Message"]
    preset = inputs.Type.change()

    @hideConnectedFields()

    @initInviteTab()
    @initMigrateTab()
    @initIntroductionTab()
    @createUserAutoComplete()

  createUserAutoComplete:->
    {fields, inputs, buttons} = @modalTabs.forms["User Details"]
    @userController = new KDAutoCompleteController
      form                : @modalTabs.forms["User Details"]
      name                : "userController"
      itemClass           : MemberAutoCompleteItemView
      itemDataPath        : "profile.nickname"
      outputWrapper       : fields.userWrapper
      selectedItemClass   : MemberAutoCompletedItemView
      listWrapperCssClass : "users"
      submitValuesAsText  : yes
      dataSource          : (args, callback)=>
        {inputValue} = args
        blacklist = (data.getId() for data in @userController.getSelectedItemData())
        KD.remote.api.JAccount.byRelevance inputValue, {blacklist}, (err, accounts)=>
          callback accounts

    @userController.on "ItemListChanged", =>
      accounts = @userController.getSelectedItemData()
      if accounts.length > 0
        account = accounts[0]
        inputs.Flags.setValue account.globalFlags?.join(',')
        userRequestLineEdit.hide()
        @showConnectedFields()
        account.fetchLimit? 'invite', (err, limit)=>
          current = 0
          if not err and limit
            current = limit.quota - limit.usage
          inputs.Invites.setPlaceHolder "Currently has #{current} invites."
      else
        userRequestLineEdit.show()
        @hideConnectedFields()

    fields.Username.addSubView userRequestLineEdit = @userController.getView()

  initInviteTab:->
    inviteForm = @modalTabs.forms["Send Beta Invites"]
    KD.remote.api.JInvitation.betaInviteCount (res)->
      inviteForm.inputs.currentState.updatePartial res

  initMigrateTab:->
    migrateForm = @modalTabs.forms["Migrate Kodingen Users"]
    KD.remote.api.JOldUser.__currentState (res)->
      migrateForm.inputs.currentState.updatePartial res

  hideConnectedFields:->
    {fields, inputs, buttons} = @modalTabs.forms["User Details"]
    fields.Impersonate.hide()
    buttons.Update.hide()
    fields.Invites.hide()
    inputs.Invites.setValue ''
    fields.Flags.hide()
    inputs.Flags.setValue ''

  showConnectedFields:->
    {fields, inputs, buttons} = @modalTabs.forms["User Details"]
    fields.Impersonate.show()
    fields.Flags.show()
    fields.Invites.show()
    inputs.Invites.setPlaceHolder 'Loading...'
    buttons.Update.show()

  initIntroductionTab: ->
    parentView = @modalTabs.forms["Introduction"]
    parentView.addSubView new IntroductionAdmin { parentView }


class IntroductionAdmin extends JView

  constructor: (options = {}, data) ->

    super options, data

    @currentTimestamp = Date.now()

    @buttonsContainer = new KDView
      cssClass : "introduction-admin-buttons"

    @buttonsContainer.addSubView @addButton = new KDButtonView
      cssClass : "editor-button"
      title    : "Add New Introduction Group"
      callback : => @showForm()

    @container = new KDView
      cssClass : "introduction-admin-content"

    @container.addSubView @loader = new KDLoaderView
      size     :
        width  : 36

    @container.addSubView @notFoundText = new KDView
      cssClass : "introduction-not-found"
      partial  : "There is no introduction yet."
    @notFoundText.hide()

    @container.addSubView @introListContainer = new KDView

    @fetchData()

    @on "IntroductionItemDeleted", (snippet) =>
      @snippets.splice @snippets.indexOf(snippet), 1
      if @snippets.length is 0
        @introListContainer.hide()
        @notFoundText.show()

  reload: ->
    parentView = @getOptions().parentView
    parentView.addSubView new IntroductionAdmin { parentView }
    @destroy()

  fetchData: ->
    KD.remote.api.JIntroSnippet.fetchAll (err, snippets) =>
      @loader.hide()
      @snippets = snippets
      return @notFoundText.show() if snippets.length is 0

      @introListContainer.addSubView new KDView
        cssClass : "admin-introduction-item admin-introduction-header"
        partial  : """
          <div class="cell name">Title</div>
          <div class="cell mini">Count</div>
          <div class="cell mini">In Use</div>
          <div class="cell mini">Overlay</div>
          <div class="cell mini">Visibility</div>
        """

      for snippet in snippets
        @introListContainer.addSubView new IntroductionItem
          delegate: @
        ,snippet

  showForm: (type = "Group", data = @getData(), actionType = "Insert", addingToAGroup = no) ->
    @buttonsContainer.hide()
    @container.hide()
    @addSubView @form = new IntroductionAdminForm {
      type
      actionType
      addingToAGroup
      delegate: @
    }
    , data

    @form.on "IntroductionFormNeedsReload", => @reload()

  viewAppended: ->
    super
    @loader.show()

  pistachio: ->
    """
      {{> @buttonsContainer}}
      {{> @container}}
    """

class IntroductionItem extends JView

  constructor: (options = {}, data) ->

    options.cssClass = options.cssClass or "admin-introduction-item"

    super options, data

    @createElements()

  createElements: ->
    data = @getData()

    @title = new KDView
      cssClass : "cell name"
      partial  : data.title
      click    : => @setupChilds()

    @title.addSubView @arrow = new KDCustomHTMLView
      tagName  : "span"
      cssClass : "arrow"

    @addLink = new KDCustomHTMLView
      tagName  : "span"
      partial  : "<span class='icon add'></span>"
      click    : => @add()
      tooltip  :
        title  : "Add Into"

    @updateLink = new KDCustomHTMLView
      tagName  : "span"
      partial  : "<span class='icon update'></span>"
      click    : => @update()
      tooltip  :
        title  : "Update"

    @deleteLink = new KDCustomHTMLView
      tagName  : "span"
      partial  : "<span class='icon delete'></span>"
      click    : => @remove()
      tooltip  :
        title  : "Delete"

  add: ->
    @getDelegate().showForm "Item", @getData()

  update: ->
    @getDelegate().showForm "Group", @getData(), "Update"

  remove: ->
    @getData().delete => @destroy()
    @getDelegate().emit "IntroductionItemDeleted", @getData()

  setupChilds: ->
    if @childContainer
      if @isChildContainerVisible
        @childContainer.hide()
        @arrow.unsetClass "down"
        return @isChildContainerVisible = no
      else
        @childContainer.show()
        @arrow.setClass "down"
        return @isChildContainerVisible = yes
    else
      @addSubView @childContainer = new KDView
      @isChildContainerVisible = yes
      @arrow.setClass "down"

      for snippet in @getData().snippets
        @childContainer.addSubView new IntroductionChildItem delegate: @, snippet

  isExpired: (expiryDate) ->
    return new Date(expiryDate).getTime() < @getDelegate().currentTimestamp

  pistachio: ->
    data       = @getData()
    hasOverlay = if data.overlay is "yes" then "yep" else "nope"
    status     = if @isExpired(data.expiryDate) is yes then "nope" else "yep"
    visibility = if data.visibility is "allTogether" then "allTogether" else "stepByStep"

    """
      {{> @title}}
      <div class="cell mini">#{data.snippets.length}</div>
      <div class="cell icon #{status}"></div>
      <div class="cell icon #{hasOverlay}"></div>
      <div class="cell icon #{visibility}"></div>
      <div class="introduction-actions cell">
        {{> @addLink}}{{> @updateLink}}{{> @deleteLink}}
      </div>
    """

class IntroductionChildItem extends IntroductionItem

  constructor: (options = {}, data) ->

    options.cssClass = "admin-introduction-child-item"

    super options, data

  remove: ->
    @getDelegate().getData().deleteChild @getData().introId, =>
      @destroy()

  update: ->
    introductionItem      = @getDelegate()
    introductionAdmin     = introductionItem.getDelegate()
    data                  = @getData()
    data.introductionItem = introductionItem
    introductionAdmin.showForm "Item", data, "Update"

  pistachio: ->
    data = @getData()
    """
      <div class="introItemText"><b>Intro Id</b>: #{data.introId} <b>for</b>: #{data.introTitle}</div>
      <div class="introduction-actions cell">
        {{> @updateLink}}{{> @deleteLink}}
      </div>
    """

class IntroductionAdminForm extends KDFormViewWithFields

  constructor: (options = {}, data = {}) ->

    @parentData  = data
    @timestamp   = Date.now()
    @snippetType = "Code"

    groupFields  =
      Title           :
        label         : "Title"
        type          : "text"
        placeholder   : "Title of introduction group"
        defaultValue  : data.title
      ExpiryDate      :
        label         : "Expiry Date"
        type          : "text"
        placeholder   : "Best before (YYYY-MM-DD)"
        defaultValue  : data.expiryDate
        nextElement   :
          info        :
            itemClass : KDView
            partial   : "Date format should be YYYY-MM-DD. e.g. 2013-05-03"
            cssClass  : "help-text info"
      Overlay         :
        label         : "Overlay"
        type          : "select"
        defaultValue  : data.overlay
        selectOptions : [
          { title     : "Yes", value : "yes" }
          { title     : "No",  value : "no"  }
        ]
        nextElement   :
          warning     :
            itemClass : KDView
            partial   : "Please be careful when using no overlay option. It may cause UX problems."
            cssClass  : "help-text warning"
        change: =>
          @setVisibilityOfOverlayWarning @inputs.Overlay.getValue() is "no" # wtf "no"
      Visibility       :
        label         : "Visibility"
        type          : "select"
        defaultValue  : data.visibility
        selectOptions : [
          { title     : "Show all together", value : "allTogether" }
          { title     : "Show step by step", value : "stepByStep"  }
        ]

    itemFields =
      ItemInfo        :
        label         : ""
        type          : "hidden"
        nextElement   :
          GroupName   :
            itemClass : KDView
            cssClass  : "introduction-group-name"
            partial   : "You're adding an item to: <span class=\"groupName\">#{@parentData.title}</span>"
      IntroTitle      :
        label         : "Intro Title"
        type          : "text"
        defaultValue  : data.introTitle
      IntroId         :
        label         : "Intro Id"
        type          : "text"
        placeholder   : "Parent view's intro id"
        defaultValue  : data.introId
      Snippet         :
        label         : "Intro Snippet"
        itemClass     : KDView
        cssClass      : "introduction-ace-editor"
        domId         : "introduction-ace#{@timestamp}"
        defaultValue  : Encoder.htmlDecode data.snippet
        nextElement   :
          typeSwitch  :
            itemClass : KDView
            partial   : "Switch to Text Mode"
            cssClass  : "introduction-snippet-switch snippet"
            click     : => @switchMode()

    options.fields = if options.type is "Group" then groupFields else itemFields

    options.buttons =
      "Save"          :
        title         : "Save"
        style         : "modal-clean-gray"
        loader        :
          color       : "#444444"
          diameter    : 12
        callback      : (event) => @save()
      "Cancel"        :
        title         : "Cancel"
        style         : "modal-clean-gray"
        loader        :
          color       : "#444444"
          diameter    : 12
        callback      : (event) =>
          @destroy()
          @getDelegate().container.show()
          @getDelegate().buttonsContainer.show()

    super options, data

    {type, actionType} = @getOptions()

    if type is "Group"
      @setVisibilityOfOverlayWarning @parentData.overlay is "no" # wtf "no"

    if type is "Item"
      @utils.defer => @setAceEditor()
      if actionType is "Update"
        partial = "You're updating this item from: <span class=\"groupName\">#{@parentData.introductionItem.getData().title}</span>"
        @inputs.GroupName.updatePartial partial

  save: ->
    options      = @getOptions()
    {actionType, addingToAGroup} = options

    if @getOptions().type is "Group" or addingToAGroup
      return @insertParent() if actionType is "Insert"
      @updateParent()
    else
      return @insertChild() if actionType is "Insert"
      @updateChild()

  insertParent: ->
    data = @createPostData()
    if not @getOptions().addingToAGroup
      @destroy()
      @getDelegate().showForm "Item", data, "Insert", yes
    else
      @parentData.snippets.push data
      KD.remote.api.JIntroSnippet.create @parentData, =>
        @buttons["Save"].hideLoader()
        @emit "IntroductionFormNeedsReload"

  insertChild: ->
    @parentData.addChild @createPostData(), =>
      @buttons["Save"].hideLoader()
      @emit "IntroductionFormNeedsReload"

  updateParent: ->
    @parentData.update @createPostData(), =>
      @emit "IntroductionFormNeedsReload"

  updateChild: ->
    data = @createPostData()
    data.oldIntroId = @parentData.introId
    @parentData.introductionItem.getData().updateChild data, =>
      @emit "IntroductionFormNeedsReload"

  createPostData: ->
    {inputs}     = @
    snippets     = if @parentData.snippets?.length then @parentData.snippets else []

    if @getOptions().type is "Group"
      groupData =
        title      : inputs.Title.getValue()
        expiryDate : inputs.ExpiryDate.getValue()
        visibility : inputs.Visibility.getValue()
        overlay    : inputs.Overlay.getValue()
        snippets   : snippets
      return groupData

    else
      editorValue = @aceEditor?.getValue()
      snippet     = """new KDView({partial: "#{editorValue}"});""" if @snippetType is "Text"

      itemData    =
        introId    : inputs.IntroId.getValue()
        introTitle : inputs.IntroTitle.getValue()
        snippet    : snippet or editorValue

      return itemData

  setVisibilityOfOverlayWarning: (isShowing) ->
    {warning} = @inputs
    if isShowing then warning?.show() else warning?.hide()

  setAceEditor: ->
    require ["ace/ace"], (ace) =>
      domElement = document.getElementById "introduction-ace#{@timestamp}"
      @aceEditor = ace.edit domElement
      @aceEditor.setTheme "ace/theme/idle_fingers"
      @aceEditor.getSession().setMode "ace/mode/javascript"
      @aceEditor.getSession().setTabSize 2
      domElement.style.fontSize = "14px"
      @setEditorText()
      @aceEditor.commands.addCommand
        name    : 'save'
        bindKey :
          win   : 'Ctrl-S'
          mac   : 'Command-S'
        exec    : =>

  setEditorText: (text = "new KDView({\n  partial: \"\"\n});") ->
    @aceEditor.getSession().setValue Encoder.htmlDecode @parentData.snippet or text

  switchMode: ->
    {typeSwitch} = @inputs
    if @snippetType is "Code"
      typeSwitch.updatePartial "Switch to Code Mode"
      @aceEditor.getSession().setMode "ace/mode/text"
      @snippetType = "Text"
      @setEditorText ""
    else
      typeSwitch.updatePartial "Switch to Text Mode"
      @aceEditor.getSession().setMode "ace/mode/javascript"
      @snippetType = "Code"
      @setEditorText()
