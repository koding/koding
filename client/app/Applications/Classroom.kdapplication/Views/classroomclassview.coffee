class ClassroomClassView extends JView

  constructor: (options = {}, data) ->

    options.cssClass = KD.utils.curryCssClass "classroom-class", options.name

    super options, data


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
      class      : "chapters-container"


  pistachio: ->
    appView = @getDelegate()
    data    = @getData()

    """
      <div class="header-container">
        <div class="header">
          <img src="#{appView.cdnRoot}/#{data.name}.kdclass/#{data.icns["128"]}" />
          {{> @headerText}}
          {{> @startNow}}
        </div>
      </div>
      <div class="chapters">
        <p>Chapters</p>
        {{> @chaptersContainer}}
      </div>
    """