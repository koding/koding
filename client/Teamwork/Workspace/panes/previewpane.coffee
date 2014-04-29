class PreviewPane extends Pane

  constructor: (options = {}, data) ->

    options.cssClass = "preview-pane"

    super options, data

    @container    = new KDView
      cssClass    : "workspace-viewer"

    {url}         = @getOptions()
    viewerOptions =
      delegate    : this
      params      : {}

    viewerOptions.params.path = url  if url

    @container.addSubView @previewer = new PreviewerView viewerOptions

    @createSecureWarning()  unless (Cookies.get "kdproxy-usehttp") is "1"

  createSecureWarning: ->
    @secureInfo = new KDCustomHTMLView
      tagName  : "div"
      cssClass : "tw-browser-splash"
      partial  : """
        <p>You can only preview links starting with "https".</p> """

    infoText   = new KDCustomHTMLView
      tagName  : "span"
      partial  : "In order to view non-secure (http) content you can "

    httpLink   = new KDCustomHTMLView
      tagName  : "a"
      cssClass : "tw-http-link"
      partial  : "click here"
      click    : => @useHttp()

    separator  = new KDCustomHTMLView
      tagName  : "span"
      partial  : " — "

    infoLink   = new KDCustomHTMLView
      tagName  : "a"
      partial  : "why?"
      cssClass : "tw-secure-info"
      attributes:
        href   : "http://security.stackexchange.com/questions/38317/specific-risks-of-embedding-an-https-iframe-in-an-http-page"

    @secureInfo.addSubView infoText
    @secureInfo.addSubView httpLink
    @secureInfo.addSubView separator
    @secureInfo.addSubView infoLink
    @container.addSubView  @secureInfo

  useHttp: ->
    KD.getSingleton("router").handleRoute "/Activity"
    Cookies.set "kdproxy-usehttp", "1"

  pistachio: ->
    """
      {{> @header}}
      {{> @container}}
    """
