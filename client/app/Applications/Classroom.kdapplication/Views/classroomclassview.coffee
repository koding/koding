class ClassroomClassView extends JView

  constructor: (options = {}, data) ->

    options.cssClass = KD.utils.curryCssClass "classroom-class", options.name

    super options, data

    @classRoot = "#{@getDelegate().cdnRoot}/#{@getData().name}.kdclass"

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
      title      : "Start Class Now >>"

    appView.readFileContent "/#{data.name}.kdclass/#{data.splashViewText}", (markdown) =>
      @headerText.updatePartial markdown
      loader.destroy()
      @startNow.show()

    @headerText.addSubView loader

    @chaptersContainer = new KDView
      cssClass         : "chapters-container classes"

  createChapters: ->
    container = @chaptersContainer

    for chapterData, index in @getData().chapters
      chapterData.index      = index
      chapterData.className  = @getData().name
      chapterThumbView       = new ClassroomChapterThumbView
        delegate             : this
        classRoot            : @classRoot
      , chapterData
      container.addSubView chapterThumbView

  pistachio: ->
    appView = @getDelegate()
    data    = @getData()

    """
      <div class="header-container">
        <div class="header">
          <img src="#{@classRoot}/#{data.icns["128"]}" />
          {{> @headerText}}
          {{> @startNow}}
        </div>
      </div>
      <div class="chapters">
        <p>Chapters</p>
        {{> @chaptersContainer}}
      </div>
    """