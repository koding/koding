class ClassroomChapterList extends KDScrollView

  constructor: (options = {}, data) ->

    options.cssClass = "classroom-chapters"

    super options, data

    for chapter, index in @getData().chapters
      chapter.index = ++index
      @addSubView new ClassroomChapterThumbView
        delegate   : this
        courseRoot : ""
      , chapter
