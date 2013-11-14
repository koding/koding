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
      Placement       :
        label         : "Placement"
        type          : "select"
        defaultValue  : data.placement
        selectOptions : [
          { title     : "Top",    value : "top"    }
          { title     : "Right",  value : "right"  }
          { title     : "Bottom", value : "bottom"  }
          { title     : "Left",   value : "left"  }
        ]
      DelayForNext    :
        label         : "Delay for next"
        type          : "text"
        placeholder   : "Parent view's intro id"
        tooltip       :
          title       : "in ms (3000 for 3 sec.)"
          placement   : "right"
        defaultValue  : data.delayForNext or 0
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
      Callback        :
        label         : "Callback"
        itemClass     : KDView
        cssClass      : "introduction-ace-editor"
        domId         : "introduction-callback-ace#{@timestamp}"
        defaultValue  : Encoder.htmlDecode data.callback or ""

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
      @utils.defer =>
        @createAceEditor()
        @createCallbackAceEditor()
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
      editorValue = @aceEditor.getValue()
      snippet     = """new KDView({partial: "#{editorValue}"});""" if @snippetType is "Text"

      itemData    =
        introId      : inputs.IntroId.getValue()
        introTitle   : inputs.IntroTitle.getValue()
        placement    : inputs.Placement.getValue()
        snippet      : snippet or editorValue
        delayForNext : inputs.DelayForNext.getValue()
        callback     : @callbackEditor.getValue()

      return itemData

  setVisibilityOfOverlayWarning: (isShowing) ->
    {warning} = @inputs
    if isShowing then warning?.show() else warning?.hide()

  createAceEditor: (domElement) ->
    require ["ace/ace"], (ace) =>
      @aceEditor = ace.edit document.getElementById "introduction-ace#{@timestamp}"
      @setAceEditor @aceEditor
      text = "new KDView({\n  partial: \"\"\n});"
      @setEditorContent @aceEditor, Encoder.htmlDecode @parentData.snippet or text

  createCallbackAceEditor: ->
    require ["ace/ace"], (ace) =>
      @callbackEditor = ace.edit document.getElementById "introduction-callback-ace#{@timestamp}"
      @setAceEditor @callbackEditor
      @setEditorContent @callbackEditor, Encoder.htmlDecode @parentData.callback or ""

  setAceEditor: (aceInstance, content) ->
    aceInstance.setTheme "ace/theme/idle_fingers"
    aceInstance.getSession().setMode "ace/mode/javascript"
    aceInstance.getSession().setTabSize 2
    # domElement.style.fontSize = "14px"
    aceInstance.commands.addCommand
      name    : 'save'
      bindKey :
        win   : 'Ctrl-S'
        mac   : 'Command-S'
      exec    : => # to disable browser save modal

  setEditorContent: (editor, content) ->
    editor.getSession().setValue content

  switchMode: ->
    {typeSwitch} = @inputs
    if @snippetType is "Code"
      typeSwitch.updatePartial "Switch to Code Mode"
      @aceEditor.getSession().setMode "ace/mode/text"
      @snippetType = "Text"
      @aceEditor.getSession().setValue ""
    else
      typeSwitch.updatePartial "Switch to Text Mode"
      @aceEditor.getSession().setMode "ace/mode/javascript"
      @setSnippetEditorValue()
      @snippetType = "Code"
