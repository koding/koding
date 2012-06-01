class Editor_HeaderButtons extends KDView
  triggerInputAutoSave:(pubInst,event)=>
    @inputAutoSave.inputSetValue event.state

  viewAppended:()->
    aceView  = @getDelegate()
    file     = aceView.getData()
    fieldset = new KDCustomHTMLView "fieldset"

    @inputAutoSave = new KDInputSwitch
      # label     : labelAutoSave
      name      : "auto-save"
      defaultValue : off
      callback  : (state)=>
        pane = @getDelegate().tabView.getActivePane()
        if state then pane.setAutoSave() else pane.unsetAutoSave()

    save = new EditorSaveButton
      title     : "Save"
      style     : "clean-gray editor-button save-menu"
      delegate  : @
      contextControllerClass: EditorHeaderButtons_ContextMenu
      menu      : [
        items : [
          {title : "Save as...",      id : 13,  parentId : null, function : "saveFileAs" }
          {type : 'divider',          id : 6,   parentId : null }
          {
            title : 'Autosave'
            id : 51
            parentId : null
            type : 'autosave'
            default: => 
              @getDelegate().getAutoSave()
            callback: (state) => 
              if state then @getDelegate().setAutoSave() else @getDelegate().unsetAutoSave()
          }
        ]
      ]
      callback  : ()=>
        @getDelegate().saveActiveTabContents()

    share = new KDButtonView
      title     : "Share"
      style     : "small-gray"
      icon      : yes
      iconClass : "rss"
      callback  : ()=>
        @handleEvent { type : "ShareActiveTabContents" }

    question = new KDButtonView
      title     : "Question?"
      style     : "small-gray"
      callback  : ()=>
        @handleEvent { type : "QuestionButtonClicked" }
        no

    addTab = new KDButtonView
      title     : "New File"
      style     : "small-gray"
      icon      : yes
      iconClass : "plus"
      callback  : ()=>
        @handleEvent { type : "AddNewEditorTab" }

    showSearch = new KDButtonView
      # title     : "Find"
      style     : "clean-gray editor-button"
      icon      : yes
      iconOnly  : yes
      iconClass : "search"
      callback  : ()=>
        @handleEvent { type : "ToggleSearchReplaceForm" }

    # if @getOptions().showNewPane ? yes
    #   @addSubView addTab
    # @addSubView share
    # @addSubView question
    @addSubView showSearch
    if /koding.com\/httpdocs/.test file.path
      @addSubView preview = new KDButtonView
        # title     : "Preview"
        style     : "clean-gray editor-button"
        icon      : yes
        iconOnly  : yes
        iconClass : "preview"
        callback  : ()=>
          publicPath = file.path.replace /.*\/(.*\.beta.koding.com)\/httpdocs\/(.*)/, 'http://$1/$2'
          return if publicPath is file.path
          appManager.openFileWithApplication publicPath, "Viewer.kdapplication"
    @addSubView fieldset
    @addSubView save
        
      
    # listeners below
    @listenTo
      KDEventTypes        : "AutoSaveStateDidChange"
      listenedToInstance  : @getDelegate()
      callback            : @triggerInputAutoSave
