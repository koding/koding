class ClassroomChapterThumbView extends JView

  constructor: (options = {}, data) ->

    options.tagName = "figure"

    super options, data

    subscriptionOptions = {}

    {subscription, title, description} = data

    if subscription
      if subscription is "paid"
        subscriptionOptions.cssClass = "top-badge orange"
        subscriptionOptions.partial  = "Paid"
        subscriptionOptions.tooltip  =
          title                      : "This chapter requires subscription to this course."
      else
        subscriptionOptions.cssClass = "top-badge green"
        subscriptionOptions.partial  = "Free"
        subscriptionOptions.tooltip  =
          title                      : "This is a free chapter."

    @subscriptionView = new KDCustomHTMLView subscriptionOptions

    @info = new KDCustomHTMLView
      tagName  : "span"
      cssClass : "icon info"
      tooltip  :
        offset :
          top  : 4
          left : -5
        title  : """
          <div class="app-tip">
            <header>
              <strong>#{title}</strong>
            </header>
            <p class="app-desc">
              #{description.slice(0,200)}
              #{if description.length > 199 then "..." else ""}
            </p>
          <div>
          """

    progressOptions = {}
    if @getData().completed
      progressOptions.cssClass = "completed-chapter"
      progressOptions.tooltip  =
        title                  : "You have already completed this chapter."

    @progressBar = new KDCustomHTMLView progressOptions

  click: ->
    data = @getData()
    KD.getSingleton("router").handleQuery "?course=#{data.courseName}&chapter=#{data.index + 1}"

  pistachio: ->
    options = @getOptions()
    data    = @getData()

    return """
      {{> @subscriptionView}}
      <p>
        <img src="#{options.courseRoot}/#{data.icon}" />
      </p>
      <div class="icon-container">
        {{> @info}}
      </div>
      <cite>
        <span>#{data.title}</span>
      </cite>
      {{> @progressBar}}
    """