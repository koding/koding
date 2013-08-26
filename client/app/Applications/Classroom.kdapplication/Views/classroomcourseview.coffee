class ClassroomCourseView extends JView

  constructor: (options = {}, data) ->

    options.cssClass = KD.utils.curryCssClass "classroom-course", options.name

    super options, data

    @courseRoot = "#{@getDelegate().cdnRoot}/#{@getData().name}.kdcourse"

    @buildSplashView()
    @createChapters()

  buildSplashView: ->
    appView      = @getDelegate()
    data         = @getData()

    @headerText  = new KDView
      cssClass   : "header-text"

    loader       = new KDLoaderView
      showLoader : yes
      size       :
        width    : 40

    @startNow    = new KDButtonView
      cssClass   : "cupid-green start-now-button hidden"
      title      : "Start Course Now >>"

    appView.readFileContent "/#{data.name}.kdcourse/#{data.splashViewText}", (markdown) =>
      @headerText.updatePartial markdown
      loader.destroy()
      @startNow.show()

    @headerText.addSubView loader

    @chaptersContainer = new KDView
      cssClass         : "chapters-container courses"

  createChapters: ->
    container  = @chaptersContainer
    courseName = @getData().name
    appStorage = KD.getSingleton("appStorageController").storage "Classroom"
    completed  = appStorage.getValue("CompletedChapters")?[courseName]

    for chapterData, index in @getData().chapters
      chapterData.index       = index
      chapterData.courseName  = courseName
      chapterData.completed   = completed.indexOf(chapterData.title) > -1

      chapterThumbView        = new ClassroomChapterThumbView
        delegate              : this
        courseRoot            : @courseRoot
      , chapterData
      container.addSubView chapterThumbView

  pistachio: ->
    appView = @getDelegate()
    data    = @getData()

    """
      <div class="header-container">
        <div class="header">
          <img src="#{@courseRoot}/#{data.icns["128"]}" />
          {{> @headerText}}
          {{> @startNow}}
        </div>
      </div>
      <div class="chapters">
        <p>Chapters</p>
        {{> @chaptersContainer}}
      </div>
    """