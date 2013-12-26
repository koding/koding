class ClassroomChapterList extends KDScrollView

  constructor: (options = {}, data) ->

    options.cssClass or= "classroom-chapters"

    super options, data

    courseName = @getData().name
    appStorage = KD.getSingleton("appStorageController").storage "Classroom", "1.2.1"
    completed  = appStorage.getValue("Completed")?[courseName] or []

    for chapter, index in @getData().chapters
      chapter.index      = index
      chapter.courseName = courseName
      chapter.completed  = completed.indexOf(chapter.title) > -1

      @addSubView new ClassroomChapterThumbView
        delegate   : this
        courseRoot : @getData().resourcesRoot
      , chapter
