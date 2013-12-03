class ClassroomCourseView extends JView

  constructor: (options = {}, data) ->

    options.cssClass = KD.utils.curry "classroom-course", options.name

    super options, data

    {@resourcesRoot} = @getData()

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

    appView.readFileContent "#{@resourcesRoot}/#{data.splashViewText}", (markdown) =>
      @headerText.updatePartial markdown
      loader.destroy()
      @startNow.show()

    @headerText.addSubView loader

    @chaptersContainer = new KDView
      cssClass         : "chapters-container courses"

  createChapters: ->
    @chaptersContainer.addSubView new ClassroomChapterList
      cssClass : "course-chapters"
    , @getData()

  pistachio: ->
    appView = @getDelegate()
    data    = @getData()

    """
      <div class="header-container">
        <div class="header">
          <img src="#{@resourcesRoot}/#{data.icns["128"]}" />
          {{> @headerText}}
          {{> @startNow}}
        </div>
      </div>
      <div class="chapters">
        <p>Chapters</p>
        {{> @chaptersContainer}}
      </div>
    """