class Editor_SearchForm extends KDView
  constructor:(options,data)->
    super
    @setClass "editor-search-wrapper"
    @collapsed = yes

    @listenTo
      KDEventTypes : "ToggleSearchReplaceForm"
      listenedToInstance : @getDelegate().headerButtons
      callback : @toggle
      
  # keyDown: (event) ->
  #   log 'key down for search form', event

  viewAppended:()->
    delegate = @getDelegate()
    @addSubView form = new KDFormView cssClass : "clearfix"

    form.addSubView @inputSearch = inputSearch = new KDInputView
      name        : "search-phrase"
      placeholder : "search..."
      
    # inputSearch.listenTo 
    #   KDEventTypes: 'KDInputViewFocus'
    #   listenedToInstance: inputSearch
    #   callback: =>
    #     log 'got focus'
    #     (@getSingleton "windowController").setKeyView @
      
    form.addSubView findButton = new KDButtonView
      style    : "clean-gray editor-button"
      title    : "Find"
      callback : ()->
        delegate.handleEvent
          type    : "EditorFind",
          search  : inputSearch.inputGetValue()

    form.addSubView inputReplace = new KDInputView
      name        : "replace-phrase"
      placeholder : "replace..."
    form.addSubView replaceButton = new KDButtonView
      style    : "clean-gray editor-button"
      title    : "Replace"
      callback : ()->
        delegate.handleEvent
          type    : "EditorReplace"
          search  : inputSearch.inputGetValue()
          replace : inputReplace.inputGetValue()
          all     : no

    form.addSubView replaceAllButton = new KDButtonView
      style     : "clean-gray editor-button"
      title     : "Replace All"
      icon      : yes
      iconClass : 'check'
      callback : ()->
        delegate.handleEvent
          type    : "EditorReplace"
          search  : inputSearch.inputGetValue()
          replace : inputReplace.inputGetValue()
          all     : yes

    # form.addSubView closeButton = new KDButtonView
    #   style     : "clean-gray editor-button to-right"
    #   icon      : yes
    #   iconClass : 'x'
    #   iconOnly  : yes
    #   callback : @collapse


    form.addSubView settingsButton = new KDButtonView
      style     : "clean-gray editor-button to-right"
      # title     : "Search Options"
      icon      : yes
      iconOnly  : yes
      iconClass : 'cog'
      callback  : () =>
        @getDelegate().handleEvent type : "EditorSearchFormOptionsShow"

  toggle:=>
    unless @collapsed then @collapse() else @expand()

  collapse:=>
    delegate = @getDelegate()
    @$().animate marginTop : "-39px",
      duration : 100
      step : -> delegate.handleEvent type : "EditorSearchFormDidHide"
    @collapsed = yes

  expand:=>
    delegate = @getDelegate()
    @$().animate marginTop : 0,
      duration : 100
      step : -> delegate.handleEvent type : "EditorSearchFormDidShow"
    @collapsed = no
