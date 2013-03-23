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
    count = @getData().repliesCount or 0
    @commentCount =
      if count is 0 then ''
      else if count is 1 then ' · One Comment'
      else " · #{count} Comments"


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
          {{ @applyTextExpansions #(title)}}
        </span>
      </div>
      <div class="blog-post-body has-markdown">
        <div class='create-date'>
          <span class='type-icon'></span>
          {time{@formatCreateDate #(meta.createdAt)}}
          {{> @tags}}#{@commentCount}
          {{> @actionLinks}}
        </div>
        {{Encoder.htmlDecode #(html)}}
      </div>
    </div>
    """
