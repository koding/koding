class StaticBlogPostActivityItemView extends StaticActivityItemChild

  constructor:(options = {}, data={})->

    options.cssClass or= "static-activity-item blog-post"
    options.tooltip  or=
      title            : "Blog Post"
      selector         : "span.type-icon"
      offset           :
        top            : 3
        left           : -5

    super options,data

    @on 'CommentLinkReceivedClick', =>
      @getSingleton('staticProfileController').emit 'CommentLinkReceivedClick'
    @on 'CommentCountClicked'     , =>
      @getSingleton('staticProfileController').emit 'CommentCountReceivedClick'

    data = @getData()

    @titleLink  = new CustomLinkView
      href      : "/#{data.slug}"
      title     : @applyTextExpansions data.title
      target    : '_blank'

  viewAppended:()->
    return if @getData().constructor is KD.remote.api.CBlogPostActivity
    super()
    @setTemplate @pistachio()
    @template.update()

    @handleExternalLinks()

  handleExternalLinks:->
    @$("div.blog-post-body > span.data a").each (i,element)->
      $(element).attr target : '_blank'

  applyTextExpansions:(str = "")->
    str = @utils.applyTextExpansions str, yes

  pistachio:->
    """
    <div class='content-item'>
      <div class='title'>
        <span class="text">
          {{> @titleLink}}
        </span>
      </div>
      <div class="blog-post-body has-markdown">
        <div class='create-date'>
          <span>
          {time{@formatCreateDate #(meta.createdAt)}}
          {{> @tags}}
          </span>
          <span>
          {{> @actionLinks}}
          </span>
        </div>
        {{Encoder.htmlDecode #(html)}}
      </div>
    </div>
    """
