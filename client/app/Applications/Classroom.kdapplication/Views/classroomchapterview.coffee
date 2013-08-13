class ClassroomChapterView extends KDView

  constructor: (options = {}, data) ->

    super options, data

    @showChaptersList = @getOptions().showChaptersList or yes

    {layout} = @getData().config
    if @showChaptersList
      @injectChapterListToLayoutConfig layout

    workspace = new CollaborativeWorkspace layout, @getData().courseManifest
    @getOptions().container.addSubView workspace

  injectChapterListToLayoutConfig: (layoutConfig) ->
    [panel] = layoutConfig.panels
    if panel.pane
      panel.layout =
        direction      : "vertical"
        sizes          : [ 50, null ]
        views          : [
          { type       : "custom", paneClass : ClassroomChapterList }
          panel.pane
        ]
      delete panel.pane