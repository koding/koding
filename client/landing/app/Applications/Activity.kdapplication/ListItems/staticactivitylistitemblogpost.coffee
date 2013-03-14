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

    @readThisLink = new CustomLinkView
      cssClass : 'read-this-link'
      title : 'Read this Blog Post'
      click : (event)=>
        event.stopPropagation()
        event.preventDefault()
        KD.getSingleton('router').handleRoute "/Activity/#{@getData().slug}", state:@getData()

  viewAppended:()->
    return if @getData().constructor is KD.remote.api.CBlogPostActivity
    super()
    @setTemplate @pistachio()
    @template.update()


  applyTextExpansions:(str = "")->
    str = @utils.applyTextExpansions str, yes

  pistachio:->
    """
    <div class='content-item'>
      <div class='title'>
        <span class="text">
        {{ @applyTextExpansions #(title)}}
        </span>
        <div class='create-date'>
          <span class='type-icon'></span>
          <time>{{$.timeago #(meta.createdAt)}}</time>
          {{> @tags}}
          {{> @actionLinks}}
        </div>
      </div>
      <div class="blog-post-body has-markdown">{{Encoder.htmlDecode #(html)}}</div>
    </div>
    """
