class BookPage extends JView

  constructor: (options = {},data) ->
    data.cssClass  or = ""
    data.content   or = ""
    # TODO : check do we really need that here?
    data.profile      = KD.whoami().profile
    data.routeURL  or = ""
    data.section   or = 0
    data.parent    or = 0
    data.showHow   or = no
    data.howToSteps or = []
    options.cssClass  = "page #{@utils.slugify data.title} #{data.cssClass} #{unless data.title then "no-header"}"
    options.tagName   = "section"

    super options, data

    @header = new KDView
      tagName   : "header"
      partial   : "#{data.title}"
      cssClass  : "hidden" unless data.title

    @content = new KDView
      tagName   : "article"
      cssClass  : "content-wrapper"
      pistachio : data.content
    , data



    konstructor = if data.embed and "function" is typeof (k = data.embed) then k else KDCustomHTMLView

    @embedded = new konstructor
      delegate : @getDelegate()

  pistachio:->

    """
    {{> @header}}
    {{> @content}}
    <div class='embedded'>
      {{> @embedded}}
    </div>
    """