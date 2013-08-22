class ClassroomChapterView extends KDView

  constructor: (options = {}, data) ->

    super options, data

    @showChaptersList = @getOptions().showChaptersList or yes

    @getOptions().container.addSubView new ClassroomWorkspace {}, @getData()

  injectChapterListToPanel: (panelConfig) ->
    if panelConfig.pane
      panel.layout =
        direction      : "vertical"
        sizes          : [ 50, null ]
        views          : [
          { type       : "custom", paneClass : ClassroomChapterList }
          panel.pane
        ]
      delete panel.pane