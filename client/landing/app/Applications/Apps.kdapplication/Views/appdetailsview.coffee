class AppDetailsView extends KDScrollView

  constructor:->

    super

    app = @getData()
    {icns, identifier, version, authorNick} = app.manifest

    @listenWindowResize()

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

    @_windowDidResize()

  _windowDidResize:->
    @setHeight @parent.getHeight() - @parent.$('.kdview.profilearea').outerHeight(no) - @parent.$('>h2').outerHeight(no)

  click:(event)->

    if $(event.target).is('header a, header a span')
      log "right"

  scroll:(event)->
    if @getScrollTop() > 20
      @parent.$('.profilearea').addClass "cast-shadow"
    else
      @parent.$('.profilearea').removeClass "cast-shadow"

  pistachio:->
    """
    <header><a href='#'>About {{#(title)}}</a></header>
    <section>{{ @utils.applyTextExpansions #(manifest.description)}}</section>
    <header><a href='#'>Screenshots</a></header>
    <section class='screenshots'>{{> @slideShow}}</section>
    <header><a href='#'>Technical Stuff</a></header>
    <section><p><p></section>
    <header><a href='#'>Reviews</a></header>
    <section>{{> @reviewView}}</section>
    """
