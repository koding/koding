class ClassroomChapterList extends KDScrollView

  constructor: (options = {}, data) ->

    options.cssClass = "classroom-chapters"

    super options, data

    for chapter, index in @getData().chapters
      chapter.index      = index
      chapter.courseName = @getData().name

      @addSubView new ClassroomChapterThumbView
        delegate   : this
        courseRoot : "#{ClassroomAppView::cdnRoot}/#{@getData().name}.kdcourse"
      , chapter
