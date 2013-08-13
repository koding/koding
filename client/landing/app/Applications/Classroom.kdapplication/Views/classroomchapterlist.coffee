class ClassroomChapterList extends KDScrollView

  constructor: (options = {}, data) ->

    options.cssClass = "classroom-chapters details-hidden"

    super options, data

    @sessionKey = "ClassroomChapterList"
    panel       = @getDelegate()
    workspace   = panel.getDelegate()
    @setData workspace.getData()

    for chapter, index in @getData().chapters
      chapter.index = ++index
      @addSubView new ClassroomChapterListItem {}, chapter


class ClassroomChapterListItem extends JView

  constructor: (options = {}, data) ->

    options.cssClass = "chapter-list-item courses"

    super options, data

    @number      = new KDView
      cssClass   : "chapter-number"
      partial    : data.index
      tooltip    :
        title    :
          """
            <div class="app-tip">
              <header>
                <strong>#{data.title}</strong>
              </header>
              <p class="app-desc">
                #{data.description.slice(0,200)}
                #{if data.description.length > 199 then "..." else ""}
              </p>
            <div>
          """

    isPaid       = @getData().subscription is "paid"
    @badge       = new KDView
      cssClass   : KD.utils.curryCssClass "top-badge", if isPaid then "orange" else "green"
      partial    : if isPaid then "Paid" else "Free"
      tooltip    :
        title    : if isPaid then "This chapter requires subscription." else "This is a free chapter!"

  pistachio: ->
    data = @getData()
    """
      {{> @number}}
      <div class="chapter-title" title="#{data.title}">#{data.title}</div>
      <div class="chapter-description">#{data.description}</div>
      {{> @badge}}
    """