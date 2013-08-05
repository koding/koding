class ClassroomAppView extends KDScrollView

  constructor: (options = {}, data) ->

    options.cssClass = "classroom-app-view"

    super options, data

    @cdnRoot     = "http://fatihacet.kd.io/cdn/classes"
    @appStorage  = new AppStorage "Classroom", "1.0"

    @createHeader()
    @fetchClasses()

    @emit "ready"

  fetchClasses: ->
    @appStorage.fetchStorage (storage) =>
      @enrolledClasses   = @appStorage.getValue("EnrolledClasses") or []
      @relatedClasses    = []
      enrolledClassNames = []

      enrolledClassNames.push enrolled.name for enrolled in @enrolledClasses

      for classDetails in @getPredefinedClasses()
        className = classDetails.name
        if @enrolledClasses.length is 0 or enrolledClassNames.indexOf(className) is -1
          @relatedClasses.push classDetails

      @addSubView @classesView = new ClassroomClassesView
        delegate : this
      ,
        enrolled : @enrolledClasses
        related  : @relatedClasses

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

  enrollToClass: (classData) ->
    @enrolledClasses.push classData
    @appStorage.setValue "EnrolledClasses", @enrolledClasses

  cancelEnrollment: (classData) ->
    pos = i for enrolled, i in @enrolledClasses when enrolled.name is classData.name
    @enrolledClasses.splice pos, 1
    @appStorage.setValue "EnrolledClasses", @enrolledClasses
    if @classesView.enrolledContainer.getSubViews().length is 1
      @classesView.noEnrolledClass.show()

  goToClass: (className, callback = noop) ->
    @readFileContent "/#{className}.kdclass/manifest.json", (manifest) =>
      manifest.startWithSplashView = yes
      @createClassView manifest
      callback()

  goToChapter: ->
    log "handle go to chapter"

  createClassView: (manifest) ->
    @getDomElement().css { left: -@getWidth(), height: 0 }
    @parent.addSubView new ClassroomClassView { delegate: this }, manifest

  handleQuery: (query) ->
    return  unless query.class

    if query.chapter
      @goToChapter query.class, query.chapter
    else
      @goToClass query.class

  getPredefinedClasses: ->
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
      KD.getSingleton("kiteController").run "curl -s #{url}", (err, content) =>
        callback @parseContent url, content
    else
      $.ajax
        url      : url
        success  : (content) ->
          callback @parseContent url, content

  parseContent: (url, content) ->
    extension = FSItem.getFileExtension url
    switch extension
      when "json"      then JSON.parse content
      when "coffee"    then log "parse to coffee"
      when "md"        then KD.utils.applyMarkdown content