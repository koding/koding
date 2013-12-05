class AppDetailsView extends KDScrollView

  constructor:->

    super

    app = @getData()
    {icns, identifier, version, authorNick} = app.manifest

    # @listenWindowResize()

    @slideShow = new KDCustomHTMLView
      tagName   : "ul"
      pistachio : do ->
        slides = app.manifest.screenshots or []
        tmpl = ''
        for slide in slides
          tmpl += "<li><img src=\"#{KD.appsUri}/#{authorNick}/#{identifier}/#{version}/#{slide}\" /></li>"
        return tmpl

    @reviewView = new ReviewView {}, app

  viewAppended:->

    @setTemplate @pistachio()
    @template.update()

  # Do we need this? ~ GG
  #   @_windowDidResize()
  # _windowDidResize:->
  #   @setHeight @parent.getHeight() - @parent.$('.kdview.profilearea').outerHeight(no) - @parent.$('>h2').outerHeight(no)

  pistachio:->
    if @getData().manifest.screenshots?.length
      screenshots = """
        <header><a href='#'>Screenshots</a></header>
        <section class='screenshots'>{{> @slideShow}}</section>
      """

    """
    <header><a href='#'>About {{#(title)}}</a></header>
    <section>{{ @utils.applyTextExpansions #(manifest.description)}}</section>
    #{screenshots or ""}
    <section><p><p></section>
    <header><a href='#'>Reviews</a></header>
    <section>{{> @reviewView}}</section>
    """
