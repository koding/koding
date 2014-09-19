class ClassroomAppView extends KDScrollView

  constructor: (options = {}, data) ->

    options.cssClass = "classroom-app-view"

    super options, data

    @appStorage  = KD.getSingleton("appStorageController").storage "Classroom", "1.2.1"

    @emit "ready"

    @on "ChapterSucceed", (chapterData) => @markChapterAsCompleted chapterData

  fetchCourses: ->
    url     = "https://raw.github.com/fatihacet/ClassroomCourses/master/manifest.json"
    storage = @appStorage

    @readFileContent url, (manifests) =>
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
    @getManifestFromAppStorage courseName, =>
      return unless @isCourseStarted()
      @createCoursesView()
      callback()

  goToChapter: (courseName, chapter) ->
    @getManifestFromAppStorage courseName, =>
      @handleGoToChapter chapter

  getManifestFromAppStorage: (courseName, callback = noop) ->
    appStorage  = @appStorage

    enrolled  = appStorage.getValue("Enrolled") or {}
    imported  = appStorage.getValue("Imported") or {}
    @manifest = enrolled[courseName] or imported[courseName] or null
    return warn "Course manifest file is not exist"  unless @manifest

    callback()

  handleGoToChapter: (chapterIndex) ->
    courseManifest = @manifest
    {chapters}     = courseManifest
    return if not chapters or not @isCourseStarted()

    @readFileContent "#{courseManifest.resourcesRoot}/#{chapters[chapterIndex].resourcesPath}", (config) =>
      @currentChapterIndex = chapterIndex
      courseMeta          =
        name              : courseManifest.name
        index             : ++chapterIndex

      @addSubView @workspace = new ClassroomWorkspace { delegate: this }, { config, courseManifest, courseMeta }
      @fetchNextCourseConfig()

  fetchNextCourseConfig: ->
    @readFileContent "#{@manifest.resourcesRoot}/#{@manifest.chapters[@currentChapterIndex + 1].resourcesPath}", (config) =>
      @nextChapterConfig = config

  createCoursesView: ->
    @addSubView new ClassroomCourseView { delegate: this }, @manifest

  markChapterAsCompleted: (data) ->
    completedCourses           = @appStorage.getValue("Completed") or {}
    {courseName, chapterTitle} = data
    completedOnCourse          = completedCourses[courseName] or []

    if completedOnCourse.indexOf(chapterTitle) is -1
      completedOnCourse.push chapterTitle
      completedCourses[courseName] = completedOnCourse

    @appStorage.setValue "Completed", completedCourses

  handleQuery: (query) ->
    @appStorage.fetchStorage (storage) =>
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
    modal = new KDModalViewWithForms
      title                     : "Import Course"
      cssClass                  : "course-import-modal"
      content                   : ""
      overlay                   : yes
      width                     : 500
      tabs                      :
        goToNextFormOnSubmit    : no
        forms                   :
          "From manifest.json"  :
            fields              :
              url               :
                label           : "Manifest URL"
                placeholder     : "Paste URL of your manifest.json and hit enter"
            buttons             :
              Import            :
                style           : "modal-clean-green"
                type            : "submit"
                loader          :
                  color         : "#1aaf5d"
              Cancel            :
                style           : "modal-cancel"
                callback        : -> modal.destroy()
            callback            : =>
              url = modal.modalTabs.forms["From manifest.json"].inputs.url.getValue()
              @importCourse url, modal
          "From a Zip File"     :
            fields              :
              url               :
                label           : "Zip file URL"
                placeholder     : "Paste URL of your zip file and hit enter"
            buttons             :
              Import            :
                style           : "modal-clean-green"
                type            : "submit"
                loader          :
                  color         : "#1aaf5d"
              Cancel            :
                style           : "modal-cancel"
                callback        : -> modal.destroy()
            callback            : =>
              @importZippedCourse modal.modalTabs.forms["From a Zip File"].inputs.url.getValue(), modal
          "From Local File"     :
            fields              :
              url               :
                type            : "hidden"
                nextElement     :
                  notYet        :
                    itemClass   : KDView
                    partial     : "This option is not supported yet."
            buttons             :
              Cancel            :
                style           : "modal-cancel"
                callback        : -> modal.destroy()

  showImportDoneModal: (coursePath) ->
    modal              = new KDBlockingModalView
      title            : "Your course imported"
      content          : "<p>Your course has been imported successfully.</p>"
      cssClass         : "modal-with-text"
      overlay          : yes
      buttons          :
        Import         :
          title        : "Let's Start"
          cssClass     : "modal-clean-green"
          callback     : =>
            KD.getSingleton("router").handleQuery coursePath
            modal.destroy()
        Close          :
          title        : "Close"
          cssClass     : "modal-cancel"
          callback     : -> modal.destroy()

  importCourse: (url, modal) ->
    @readFileContent url, (manifest) => # TODO: sanity check for course manifest.
      importedCourses = @appStorage.getValue("Imported") or {}
      importedCourses[manifest.name] = manifest
      @appStorage.setValue "Imported", importedCourses
      @showImportDoneModal "?course=#{manifest.name}"
      modal.destroy()

  importZippedCourse: (url, modal) ->
    fileName     = "course#{Date.now()}.zip"
    path         = "Documents/Classroom/Imported/zip"
    vmController = KD.getSingleton "vmController"
    notification = new KDNotificationView
      type       : "mini"
      title      : "Fetching zip file..."
      duration   : 200000
    vmController.run "mkdir -p #{path} ; cd #{path} ; wget -O #{fileName} #{url}", (err, res)->
      return warn err if err
      return warn res.stderr if res.exitStatus > 0

      notification.notificationSetTitle "Extracting zip file..."
      vmController.run "cd #{path} ; unzip #{fileName} ; rm #{fileName} ; rm -rf __MACOSX", (err, res)->
        return warn err if err
        return warn res.stderr if res.exitStatus > 0


  readFileContent: (path, callback = noop) ->
    KD.getSingleton("vmController").run "curl -kLs #{path}", (err, content) =>
      extension = FSHelper.getFileExtension path
      switch extension
        when "json"    then callback JSON.parse content
        when "md"      then callback KD.utils.applyMarkdown content
        when "coffee"  then KD.utils.compileCoffeeOnClient content, callback
