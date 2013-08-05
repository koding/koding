class ClassroomChapterView extends JView

  constructor: (options = {}, data) ->

    super options, data

    workspace = new CollaborativeWorkspace @getData().config.layout
    @getOptions().container.addSubView workspace