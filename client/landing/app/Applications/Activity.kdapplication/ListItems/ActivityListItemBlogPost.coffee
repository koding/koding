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
      cssClass : 'read-this-link'
      title : @getData().title or 'Read this Blog Post'
      click : (event)=>
        event.stopPropagation()
        event.preventDefault()
        {entryPoint} = KD.config
        KD.getSingleton('router').handleRoute "/Activity/#{@getData().slug}", {state:@getData(), entryPoint}

  viewAppended:()->
    return if @getData().constructor is KD.remote.api.CBlogPostActivity
    super()
    @setTemplate @pistachio()
    @template.update()


  applyTextExpansions:(str = "")->
    str = @utils.applyTextExpansions str, yes

  pistachio:->
    """
    {{> @settingsButton}}
    <span class="avatar">{{> @avatar}}</span>
    <div class='activity-item-right-col'>
      <!-- <h3 class='comment-title'>{{ @applyTextExpansions #(title)}}</h3> -->
      <p class="blog-post-body">{{> @readThisLink}}</p>
      <footer class='clearfix'>
        <div class='type-and-time'>
          <span class='type-icon'></span> by {{> @author}}
          <time>{{$.timeago #(meta.createdAt)}}</time>
          {{> @tags}}
        </div>
        {{> @actionLinks}}
      </footer>
      {{> @commentBox}}
    </div>
    """
