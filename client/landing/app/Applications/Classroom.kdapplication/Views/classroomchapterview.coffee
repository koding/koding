class ClassroomChapterView extends KDView

  constructor: (options = {}, data) ->

    super options, data

    workspace = new CollaborativeWorkspace @getData().config.layout
    @getOptions().container.addSubView workspace