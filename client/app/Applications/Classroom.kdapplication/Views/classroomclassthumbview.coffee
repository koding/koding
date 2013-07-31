class ClassroomClassThumbView extends JView

  constructor: (options = {}, data) ->

    options.tagName = "figure"

    super options, data

    @cdnRoot = "http://fatihacet.kd.io/cdn/classes/#{@getData().name}.kdclass/"

    devModeOptions = {}
    if data.devMode
      devModeOptions.cssClass = "top-badge gray"
      devModeOptions.partial  = "Dev Mode"

    @devMode     = new KDCustomHTMLView devModeOptions
    @icon        = new KDCustomHTMLView
      tagName    : "img"
      attributes :
        src      : "#{@cdnRoot}/#{@getData().icns['128']}"

    @deleteIcon  = new KDCustomHTMLView
      tagName    : "span"
      cssClass   : "icon delete"
      click      : ->
        log "sadasdas"

  pistachio: ->
    data   = @getData()
    return """
      {{> @devMode}}
      <p>{{> @icon}}</p>
      <div class="icon-container">
        {{> @deleteIcon}}
      </div>
      <cite>
        <span>#{data.name}</span>
        <span>#{data.version}</span>
      </cite>
    """
