class ClassroomAppView extends KDScrollView

  constructor: (options = {}, data) ->

    options.cssClass = "classroom-app-view"

    super options, data

    @appStorage  = KD.getSingleton("appStorageController").storage "Classroom", "1.101"

    @emit "ready"

    @on "ChapterSucceed", (chapterData) => @markChapterAsCompleted chapterData

  fetchCourses: ->
    url     = "https://raw.github.com/fatihacet/ClassroomCourses/master/manifest.json"
    storage = @appStorage

    @readFileContent url, (manifests) =>
      storage.ready =>
        enrolled    = storage.getValue("Enrolled")  or {}
        related     = storage.getValue("Related")   or {}
        imported    = storage.getValue("Imported")  or {}
        completed   = storage.getValue("Completed") or {}

        for manifest in manifests
          {name}        = manifest
          related[name] = manifest  unless enrolled[name] or imported[name]

        @addSubView @coursesView = new ClassroomCoursesView
          delegate : this
        , { enrolled, related, completed, imported }

  createHeader: ->
    @addSubView @header = new KDView
      cssClass : "container"
      partial  : """
        <div class="banner">
          <h1>&lt;classroom /&gt;</h1>
          <h2>Start learning, teaching and sharing together. <br /> It's your classroom and it's online and it's free!</h2>
          <img src="http://hindiurduflagship.org/wp-content/uploads/2010/11/ImportanceVideoThumbnail.jpg" />
        </div>
      """

    @header.addSubView importButton = new KDButtonView
      title    : "Import Course"
      cssClass : "cupid-green course-import-button"
      callback : @bound "showCourseImportModal"

    $(".container .banner").append $(".course-import-button") # hack to reposition button

  enrollToCourse: (courseData) ->
    enrolled = @appStorage.getValue("Enrolled") or {}
    enrolled[courseData.name] = courseData
    @appStorage.setValue "Enrolled", enrolled

  cancelEnrollment: (courseData, appStorageKey = "Enrolled") ->
    items = @appStorage.getValue appStorageKey
    delete items[courseData.name]
    @appStorage.setValue appStorageKey, items

    # TODO: Get item count from appStorage, subview count may mislead
    if @coursesView.enrolledContainer.getSubViews().length is 1
      @coursesView.noEnrolledCourse.show()

  goToCourse: (courseName, callback = noop) ->
    @appStorage.ready =>
      enrolled = @appStorage.getValue "Enrolled"
      manifest = course for course in enrolled when course.name is courseName

      @readFileContent url, (@manifest) =>
        return unless @isCourseStarted()
        manifest.startWithSplashView = yes
        @createCoursesView manifest
        callback()

  goToChapter: (courseName, chapter) ->
    if @manifest
      @handleGoToChapter chapter
    else
      @readFileContent "/#{courseName}.kdcourse/manifest.json", (@manifest) =>
        @handleGoToChapter chapter

  handleGoToChapter: (chapterIndex) ->
    courseManifest = @manifest
    {chapters}     = courseManifest
    return if not chapters or not @isCourseStarted()

    @readFileContent "/#{courseManifest.name}.kdcourse/#{chapters[chapterIndex].resourcesPath}", (config) =>
      @currentChapterIndex = chapterIndex
      courseMeta          =
        name              : courseManifest.name
        index             : ++chapterIndex

      @addSubView @workspace = new ClassroomWorkspace { delegate: this }, { config, courseManifest, courseMeta }
      @fetchNextCourseConfig()

  fetchNextCourseConfig: ->
    @readFileContent "/#{@manifest.name}.kdcourse/#{@manifest.chapters[@currentChapterIndex + 1].resourcesPath}", (config) =>
      @nextChapterConfig = config

  createCoursesView: (manifest) ->
    @addSubView new ClassroomCourseView { delegate: this }, manifest

  markChapterAsCompleted: (data) ->
    completedCourses           = @appStorage.getValue("CompletedChapters") or {}
    {courseName, chapterTitle} = data
    completedOnCourse          = completedCourses[courseName] or []

    if completedOnCourse.indexOf(chapterTitle) is -1
      completedOnCourse.push chapterTitle
      completedCourses[courseName] = completedOnCourse

    @appStorage.setValue "CompletedChapters", completedCourses

  handleQuery: (query) ->
    @destroySubViews()
    unless query.course
      @createHeader()
      @fetchCourses()
    else
      if query.chapter
        @goToChapter query.course, query.chapter - 1
      else
        @goToCourse query.course

  isCourseStarted: ->
    {startDate} = @manifest

    return yes if not startDate or Date.now() > new Date startDate

    @addSubView notStarted = new KDView
      cssClass : "not-started-yet"
      partial  : "<p>This course is not started yet, come back soon!</p>"

    notStarted.addSubView new KDButtonView
      cssClass : "clean-gray"
      title    : "EMAIL ME BEFORE START"

    notStarted.addSubView new KDButtonView
      cssClass : "cupid-green"
      title    : "TEACH YOUR COURSE"

    return no

  showCourseImportModal: ->
    modal              = new KDModalView
      title            : "Import Course via URL"
      content          : "<p>Type URL of your course manifest.json and hit enter.</p>"
      cssClass         : "workspace-modal join-modal"
      overlay          : yes
      width            : 500
      buttons          :
        Import         :
          title        : "Start Import"
          cssClass     : "modal-clean-green"
          loader       :
            color      : "#FFFFFF"
            diameter   : 13
          callback     : => @importCourse urlInput.getValue(), modal
        Close          :
          title        : "Close"
          cssClass     : "modal-cancel"
          callback     : -> modal.destroy()

    modal.addSubView urlInput = new KDHitEnterInputView
      type             : "text"
      placeholder      : "Path to course manifest.json"
      callback         : => @importCourse urlInput.getValue(), modal

  showImportDoneModal: ->
    modal              = new KDBlockingModalView
      title            : "Your course imported"
      content          : "<p>Your course has been imported successfully.</p>"
      cssClass         : "modal-with-text"
      overlay          : yes
      buttons          :
        Import         :
          title        : "Let's Start"
          cssClass     : "modal-clean-green"
          callback     : => log "dsada"
        Close          :
          title        : "Close"
          cssClass     : "modal-cancel"
          callback     : -> modal.destroy()

  importCourse: (url, modal) ->
    modal.buttons.Import.showLoader()
    @readFileContent url, (manifest) => # TODO: sanity check for course manifest.
      importedCourses = @appStorage.getValue("Imported") or {}
      importedCourses[manifest.name] = manifest
      @appStorage.setValue "Imported", importedCourses
      @showImportDoneModal()
      modal.buttons.Import.hideLoader()
      modal.destroy()

  readFileContent: (path, callback = noop) ->
    url = if path.indexOf("http") is 0 then path else "#{path}"

    KD.getSingleton("vmController").run "curl -s #{url}", (err, content) =>
      extension = FSItem.getFileExtension url
      switch extension
        when "json"    then callback JSON.parse content
        when "md"      then callback KD.utils.applyMarkdown content
        when "coffee"  then KD.utils.compileCoffeeOnClient content, callback
