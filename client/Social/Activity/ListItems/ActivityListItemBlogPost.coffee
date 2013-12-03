class BlogPostActivityItemView extends ActivityItemChild

  constructor:(options = {}, data={})->

    options.cssClass or= "activity-item blog-post"
    options.tooltip  or=
      title            : "Blog Post"
      selector         : "span.type-icon"
      offset           :
        top            : 3
        left           : -5

    super options,data

    @readThisLink = new CustomLinkView
      title : @getData().title or 'Read this Blog Post'
      click : (event)=>
        event.stopPropagation()
        event.preventDefault()
        {entryPoint} = KD.config
        KD.getSingleton('router').handleRoute "/Activity/#{@getData().slug}", {state:@getData(), entryPoint}

  viewAppended:->
    return if @getData().constructor is KD.remote.api.CBlogPostActivity
    super()
    @setTemplate @pistachio()
    @template.update()


  applyTextExpansions:(str = "")->
    str = @utils.applyTextExpansions str, yes

  pistachio:->
    """
      {{> @avatar}}
      <div class="activity-item-right-col">
        <span class="author-name">{{> @author}}</span>
        <h3 class="blog-post-title">{{> @readThisLink}}</h3>
        <p class="body no-scroll has-markdown force-small-markdown">
          {{@utils.shortenText @utils.applyMarkdown Encoder.htmlDecode #(body)}}
        </p>
      </div>
      <footer>
        {{> @actionLinks}}
        <time>{{$.timeago #(meta.createdAt)}}</time>
      </footer>
      {{> @commentBox}}
    """

    # """
    # {{> @settingsButton}}
    # <span class="avatar">{{> @avatar}}</span>
    # <div class='activity-item-right-col'>
    #   <!-- <h3 class='comment-title'>{{ @applyTextExpansions #(title)}}</h3> -->
    #   <h3 class="blog-post-body">{{> @readThisLink}}</h3>
    #   <div class="activity-content-container discussion">
    #     <p class="body no-scroll has-markdown force-small-markdown">
    #       {{@utils.shortenText @utils.applyMarkdown Encoder.htmlDecode #(body)}}
    #     </p>
    #   </div>
    #   <footer class='clearfix'>
    #     <div class='type-and-time'>
    #       <span class='type-icon'></span> {{> @contentGroupLink }} by {{> @author}}
    #       <time>{{$.timeago #(meta.createdAt)}}</time>
    #       {{> @tags}}
    #     </div>
    #     {{> @actionLinks}}
    #   </footer>
    #   {{> @commentBox}}
    # </div>
    # """
