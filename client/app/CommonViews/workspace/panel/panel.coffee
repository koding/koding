class Panel extends JView

  constructor: (options = {}, data) ->

    options.cssClass = "panel"

    super options, data

    @headerButtons  = {}
    @panesContainer = []
    @panes          = []
    @header         = new KDCustomHTMLView

    {title}         = options
    buttonsLength   = options.buttons?.length

    @createHeader title     if title or buttonsLength
    @createHeaderButtons()  if buttonsLength
    @createHeaderHint()     if options.hint

    @createLayout()

  createHeader: (title = "") ->
    @header     = new KDView
      cssClass  : "inner-header"
      partial   : """<span class="title">#{title}</span>"""

  createHeaderButtons: ->
    @getOptions().buttons.forEach (buttonOptions) =>
      buttonView = new KDButtonView
        title    : buttonOptions.title
        cssClass : buttonOptions.cssClass
        callback : =>
          buttonOptions.callback @, @getDelegate()

      @headerButtons[buttonOptions.title] = buttonView
      @header.addSubView buttonView

  createHeaderHint: ->
    @header.addSubView new KDCustomHTMLView
      cssClass  : "help"
      click     : => @showHintModal()

  createLayout: ->
    {pane, layout} = @getOptions()
    @container     = new KDView
      cssClass     : "panel-container"

    if pane
      @container.addSubView @createPane pane
    else if layout
      @container.addSubView new WorkspaceLayout
        delegate      : @
        layoutOptions : layout
    else
      warn "no layout config or pane passed to create a panel"

  # createPanes: ->
  #   for paneOptions, index in @getOptions().panes
  #     @createPane paneOptions, @getPaneContainerByIndex index

  createPane: (paneOptions) ->
    PaneClass            = @getPaneClass paneOptions.type
    paneOptions.delegate = @
    pane                 = new PaneClass paneOptions

    # targetContainer.addSubView pane
    @panes.push pane
    @emit "NewPaneCreated", pane
    return  pane

  # GETTERS #
  # getPaneContainerByIndex: (index) ->
  #   return  @panesContainer[index]

  getPaneClass: (paneType) ->
    paneTypesToPaneClass =
      "terminal"         : @TerminalPaneClass
      "editor"           : @EditorPaneClass
      "video"            : @VideoPaneClass
      "preview"          : @PreviewPaneClass
      "finder"           : @FinderPaneClass
      "tabbedEditor"     : @TabbedEditorPaneClass

    return  paneTypesToPaneClass[paneType]

  # createSplitView: (type, views) ->
  #   splitView = new SplitViewWithOlderSiblings {
  #     resizable : yes
  #     sizes     : ["50%", "50%"]
  #     type
  #     views
  #   }
  #   splitView.on "ResizeDidStop", =>
  #     for pane in @splitView.panelPanes
  #       pane.getSubViews().first.emit "PaneResized"
  #   return  splitView

  # createSingleLayout: ->
  #   view       = new KDView
  #     cssClass : "panel-container"

  #   @container.addSubView view
  #   @panesContainer.push view

  # createDoubleLayout: ->
  #   pane1      = new KDView
  #   pane2      = new KDView
  #   @splitView = @createSplitView "vertical", [pane1, pane2]

  #   @container.addSubView @splitView
  #   @panesContainer.push pane1, pane2
  #   @splitView.panelPanes = [pane1, pane2]

  # createTripleLayout: ->
  #   pane1           = new KDView
  #   pane2           = new KDView
  #   pane3           = new KDView
  #   rightInnerSplit = @createSplitView "horizontal", [pane2, pane3]
  #   @splitView      = @createSplitView "vertical", [pane1, rightInnerSplit]

  #   @container.addSubView @splitView
  #   @panesContainer.push pane1, pane2, pane3
  #   @splitView.panelPanes = [pane1, pane2, pane3]

  # createQuadrupleLayout: ->
  #   pane1             = new KDView
  #   pane2             = new KDView
  #   pane3             = new KDView
  #   pane4             = new KDView
  #   leftInnerSplit    = @createSplitView "horizontal", [pane1, pane2]
  #   rightInnerSplit   = @createSplitView "horizontal", [pane3, pane4]
  #   @splitView        = @createSplitView "vertical",   [leftInnerSplit, rightInnerSplit]

  #   @container.addSubView @splitView
  #   @panesContainer.push pane1, pane2, pane3, pane4
  #   @splitView.panelPanes = [pane1, pane2, pane3, pane4]

  showHintModal: ->
    options        = @getOptions()
    modal          = new KDModalView
      cssClass     : "workspace-modal"
      overlay      : yes
      title        : options.title
      content      : options.hint
      buttons      :
        Close      :
          title    : "Close"
          cssClass : "modal-cancel"
          callback : -> modal.destroy()

  viewAppended: ->
    super
    @getDelegate().emit "NewPanelAdded", @
    # @createPanes()

  pistachio: ->
    """
      {{> @header}}
      {{> @container}}
    """

Panel::EditorPaneClass        = EditorPane
Panel::TabbedEditorPaneClass  = EditorPane
Panel::TerminalPaneClass      = TerminalPane
Panel::VideoPaneClass         = VideoPane
Panel::PreviewPaneClass       = PreviewPane
