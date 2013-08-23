class ClassroomAppView extends KDScrollView

  constructor: (options = {}, data) ->

    options.cssClass = "classroom-app-view"

    super options, data

    @appStorage  = KD.getSingleton("appStorageController").storage "Classroom", "1.0"

    @emit "ready"

    @on "ChapterSucceed", (chapterMeta) =>
      # @appStorage

  fetchCourses: ->
    @appStorage.ready =>
      @enrolledCourses    = @appStorage.getValue("EnrolledCourses") or []
      @relatedCourses     = []
      enrolledCourseNames = []

      enrolledCourseNames.push enrolled.name for enrolled in @enrolledCourses

      for courseDetails in @getPredefinedCourses()
        courseName = courseDetails.name
        if @enrolledCourses.length is 0 or enrolledCourseNames.indexOf(courseName) is -1
          @relatedCourses.push courseDetails

      @addSubView @coursesView = new ClassroomCoursesView
        delegate : this
      ,
        enrolled : @enrolledCourses
        related  : @relatedCourses

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

  enrollToCourse: (courseData) ->
    @enrolledCourses.push courseData
    @appStorage.setValue "EnrolledCourses", @enrolledCourses

  cancelEnrollment: (courseData) ->
    pos = i for enrolled, i in @enrolledCourses when enrolled.name is courseData.name
    @enrolledCourses.splice pos, 1
    @appStorage.setValue "EnrolledCourses", @enrolledCourses
    if @coursesView.enrolledContainer.getSubViews().length is 1
      @coursesView.noEnrolledCourse.show()

  goToCourse: (courseName, callback = noop) ->
    @readFileContent "/#{courseName}.kdcourse/manifest.json", (@manifest) =>
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
    return unless chapters

    @readFileContent "/#{courseManifest.name}.kdcourse/#{chapters[chapterIndex].resourcesPath}", (config) =>
      courseMeta   =
        name       : courseManifest.name
        index      : ++chapterIndex

      @addSubView new ClassroomWorkspace { delegate: this }, { config, courseManifest, courseMeta }

  createCoursesView: (manifest) ->
    @addSubView new ClassroomCourseView { delegate: this }, manifest

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

  getPredefinedCourses: ->
    [
      {
        devMode    : true
        version    : "0.1"
        name       : "CoffeeScript"
        author     : "Fatih Acet"
        authorNick : "fatihacet"
        icns       :
          "128"    : "./resources/icon.128.png"
      }
      {
        devMode    : true
        version    : "0.1"
        name       : "JavaScript"
        author     : "Fatih Acet"
        authorNick : "fatihacet"
        icns       :
          "128"    : "./resources/icon.128.png"
      }
      {
        devMode    : true
        version    : "0.1"
        name       : "PHP"
        author     : "Fatih Acet"
        authorNick : "fatihacet"
        icns       :
          "128"    : "./resources/icon.128.png"
      }
    ]

  readFileContent: (relativePath, callback = noop) ->
    url = "#{@cdnRoot}#{relativePath}"

    if location.hostname is "localhost"
      KD.getSingleton("vmController").run "curl -s #{url}", (err, content) =>
        extension = FSItem.getFileExtension url
        switch extension
          when "json"    then callback JSON.parse content
          when "md"      then callback KD.utils.applyMarkdown content
          when "coffee"  then KD.utils.compileCoffeeOnClient content, callback

  cdnRoot: "http://fatihacet.kd.io/cdn/courses"