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
      newPane = @createPane pane
      @container.addSubView newPane
      @getDelegate().emit "AllPanesAddedToPanel", @, [newPane]
    else if layout
      @layoutContainer = new WorkspaceLayout
        delegate      : @
        layoutOptions : layout

      @container.addSubView @layoutContainer

      @layoutContainer.on "viewAppended", =>
        @resizeLayoutContainer()

    else
      warn "no layout config or pane passed to create a panel"

  createPane: (paneOptions) ->
    PaneClass            = @getPaneClass paneOptions.type
    paneOptions.delegate = @
    pane                 = new PaneClass paneOptions

    @panes.push pane
    @emit "NewPaneCreated", pane
    return  pane

  getPaneClass: (paneType) ->
    paneTypesToPaneClass =
      "terminal"         : @TerminalPaneClass
      "editor"           : @EditorPaneClass
      "video"            : @VideoPaneClass
      "preview"          : @PreviewPaneClass
      "finder"           : @FinderPaneClass
      "tabbedEditor"     : @TabbedEditorPaneClass

    return  paneTypesToPaneClass[paneType]

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

  resizeLayoutContainer: ->
    @layoutContainer.setHeight @layoutContainer.getHeight() - @header.getHeight()  if @header

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
