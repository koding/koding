class EmbedBoxLinksViewItem extends KDListItemView

  constructor:(options={}, data)->

    options = $.extend {}, options,
      tooltip     :
        title     : data.url
        placement : 'above'
        offset    : 3
        delayIn   : 300
        html      : yes
        animate   : yes

    super options,data

    @linkUrl = data.url
    @setClass 'embed-link-item'

    # visible link shortening here
    # http://www.foo.bar/baz -> www.foo.bar
    @linkUrlShort = @linkUrl.replace(/(ht|f)tp(s)?\:\/\//, '')
                    .replace(/\/.*/, '')

    @linkButton = new KDButtonView
      title    : @linkUrlShort
      style    : 'transparent'
      callback : @bound 'changeEmbed'

  changeEmbed:->
    @makeActive()
    # KDListView -> EmbedBoxLinksView -> EmbedBox .embedUrl
    @getDelegate().getDelegate().getDelegate().embedUrl @linkUrl

  makeActive:->
    item.unsetClass 'active' for item in @getDelegate().items
    @setClass 'active'

  viewAppended: JView::viewAppended
  pistachio:->
    """
    <div class="embed-link-wrapper">
      {{> @linkButton}}
    </div>
    """


class EmbedBoxLinksView extends KDView

  constructor:(options={}, data)->
    super options,data

    @linkList = new KDListView
      cssClass : 'embed-link-list layout-wrapper'
      delegate :@
      itemClass : EmbedBoxLinksViewItem
    ,{}

    @hide()

  clearLinks:-> @linkList.empty()

  setLinks:(links=[])->
    unless Array.isArray(links) and links.length > 0
      @clearLinks()
      return @hide()

    if links.length > 1 then @show() else @hide()

    # smarter link adding (keep links already in there intact)
    currentLinks = (item.data.url for item in @linkList.items)
    newLinks     = _.difference links, currentLinks
    isAllNew     = newLinks.length is links.length
    
    @clearLinks()                    if isAllNew
    @linkList.addItem url : link     for link in newLinks
    @linkList.items[0].makeActive()  if isAllNew

  viewAppended: JView::viewAppended
  pistachio:->
    """
    {{> @linkList}}
    """


class EmbedBoxLinkView extends KDView

  constructor:(options={}, data)->
    super options, data

    @embedImage = new EmbedBoxLinkViewImage
      cssClass : 'preview_image'
      delegate : @
    ,data

    @embedText = new EmbedBoxLinkViewText
      cssClass  : 'preview_text'
      hasConfig : data.link_options.hasConfig or no
      delegate  : @
    ,data

    @embedImageSwitch = new EmbedBoxLinkViewImageSwitch
      cssClass : 'preview_link_pager'
      delegate : @
    ,data

  render:->
    @template.update()
    super()
    @loadImages()

  viewAppended:->
    JView::viewAppended.call this
    @loadImages()

  loadImages:->
    do =>
      @utils.defer =>
        @$('img').each (i,element)->
          if $(element).attr 'data-src'
            $(element).attr 'src' : $(element).attr('data-src')
            $(element).removeAttr 'data-src'
          element

  pistachio:->
    """
    <div class="embed embed-link-view custom-link">
      {{> @embedImageSwitch}}
      {{> @embedImage}}
      {{> @embedText}}
    </div>
    """


class EmbedBoxLinkViewImageSwitch extends KDView

  constructor:(options={}, data)->
    super options, data

    @hide()  if (not data.link_options.hasConfig? or\
                 not data.link_embed.images? or\
                 data.link_embed.images.length < 2)

    @imageIndex = 0

  getImageIndex:-> @imageIndex
  setImageIndex:(@imageIndex)->

  click:(event)->
    oembed = @getData().link_embed
    return  unless $(event.target).hasClass 'preview_link_switch' or oembed

    event.preventDefault()
    event.stopPropagation()

    # There are 1+ more images beyond the current one
    if $(event.target).hasClass('next') and\
       oembed.images?.length-1 > @getImageIndex()

      @setImageIndex @getImageIndex() + 1
      @$('a.preview_link_switch.previous').removeClass 'disabled'

    # There are 1+ more images before the current one
    if $(event.target).hasClass('previous') and @getImageIndex() > 0
      @setImageIndex @getImageIndex() - 1
      @$('a.preview_link_switch.next').removeClass 'disabled'

    # Refresh the image with the new src data
    if @getImageIndex() < oembed.images.length-1
      imgSrc = oembed.images?[@getImageIndex()]?.url
      if imgSrc
        @getDelegate().embedImage.setSrc @utils.proxifyUrl imgSrc
      else
        # imgSrc is undefined - this would be the place for a default
        fallBackImgSrc = 'https://koding.com/images/service_icons/Koding.png'
        @getDelegate().embedImage.setSrc fallBackImgSrc

      # Either way, set the imageIndex to the appropriate nr
      @getDelegate().getDelegate().setImageIndex @getImageIndex()

    else
      # imageindex out of bounds - displaying default image
      # (first in the images array) the pistachio will also take care
      # of this

      defaultImgSrc = oembed.images?[0]?.url
      @getDelegate().embedImage.setSrc defaultImgSrc

    @$('span.thumb_nr').html @getImageIndex()+1

    # When we're at 0/x or x/x, disable the next/prev buttons
    if @getImageIndex() is 0
      @$('a.preview_link_switch.previous').addClass 'disabled'

    else if @getImageIndex() is (oembed.images?.length-1)
      @$('a.preview_link_switch.next').addClass 'disabled'

  viewAppended: JView::viewAppended
  pistachio:->
    """
    <a class="preview_link_switch previous #{if @getImageIndex() is 0 then "disabled" else ""}">&lt;</a><a class="preview_link_switch next #{if @getImageIndex() is data?.link_embed?.images?.length then "disabled" else ""}">&gt;</a>
    <div class="thumb_count"><span class="thumb_nr">#{@getImageIndex()+1 or "1"}</span>/<span class="thumb_all">#{@getData()?.link_embed?.images?.length}</span> <span class="thumb_text">Thumbs</span></div>
    """


class EmbedBoxImageView extends KDView

  constructor:(options={}, data)->
    super data.link_options, data

    oembed = @getData().link_embed

    @loader = new KDLoaderView
    @image  = new KDCustomHTMLView
      tagName     : 'img'
      bind        : 'error load'
      attributes  :
        src       : 'data:image/gif;base64,R0lGODlhAQABAAAAACH5BAEKAAEALAAAAAABAAEAAAICTAEAOw=='
        'data-src': (@utils.proxifyUrl oembed.images?[0]?.url) or 'https://koding.com/images/small-loader.gif'
        title     : oembed.title or ''
      error       : =>
        unless @getDelegate().getOptions().hasConfig # do not hide for widgets
          @getDelegate().hide()
        else
          new KDNotificationView
            title : 'The image you are trying to embed can not be retrieved'
            duration : 5000

  render:->
    super()
    @loadImages()

  viewAppended:->
    JView::viewAppended.call this
    @loader.show()

  loadImages:->
    do =>
      @utils.defer =>
        @loader.hide()
        if @image.$().attr 'data-src'
          @image.setDomAttributes src : @image.$().attr('data-src')
          @image.$().removeAttr 'data-src'

  pistachio:->
    """
    <div class="embed embed-image-view custom-image">
      <a href="#{@getData().link_url or '#'}" target="_blank">
        {{> @image}}
      </a>
    </div>
    """


class EmbedBoxObjectView extends KDView

  viewAppended: JView::viewAppended
  pistachio:->
    """
    <div class="embed embed-object-view custom-object">
      #{Encoder.htmlDecode @getData().link_embed?.object?.html}
    </div>
    """


class EmbedBoxLinkViewImage extends KDView

  constructor:(options={}, data)->
    super options, data

    oembed = @getData().link_embed

    @hide()  unless oembed?.images?.length > 1

    @imageLink    = @utils.proxifyUrl(oembed.images?[0]?.url) or\
                    'data:image/gif;base64,R0lGODlhAQABAAAAACH5BAEKAAEALAAAAAABAAEAAAICTAEAOw==' # hardcode a default

    altSuffix     = if oembed.author_name then " by #{oembed.author_name}" else ''
    @imageAltText = oembed.title + altSuffix

    @imageView = new KDCustomHTMLView
      tagName      : 'img'
      cssClass     : 'thumb'
      bind         : 'error'
      error        : @bound 'hide'
      attributes   :
        'data-src' : @imageLink
        src        : 'data:image/gif;base64,R0lGODlhAQABAAAAACH5BAEKAAEALAAAAAABAAEAAAICTAEAOw=='
        alt        : @imageAltText
        title      : @imageAltText
      click        : (event)=>
        if @videoPopup?
          event.stopPropagation()
          event.preventDefault()
          @videoPopup.openVideoPopup()

  # this will get called from the image-switch click events to update the preview
  # images when browsing the available embed links
  setSrc:(url='data:image/gif;base64,R0lGODlhAQABAAAAACH5BAEKAAEALAAAAAABAAEAAAICTAEAOw==')->
    @imageView.setDomAttributes src : url

  viewAppended:->
    JView::viewAppended.call this

    if @getData().link_embed?.object?.type is 'video'
      @videoPopup = new VideoPopup
        delegate : @imageView
        title    : @getData().link_embed?.title or 'Untitled Video'
        thumb    : @getData().link_embed?.images?[0]?.url
      , @getData().link_embed?.object?.html

  pistachio:->
    """
    <a class="preview_link" target="_blank" href="#{@getData().link_url or @getData().link_embed?.url}">
      {{> @imageView}}
    </a>
    """

class EmbedBoxLinkViewText extends KDView

  constructor:(options={},data)->
    super options, data

    @embedTitle = new EmbedBoxLinkViewTitle
      tagName    : 'a'
      cssClass   : 'preview_text_link'
      attributes :
        href     : data.link_url
        target   : '_blank'
      hasConfig  : options.hasConfig or no
    , data

    @embedAuthor   = new EmbedBoxLinkViewAuthor cssClass: 'author_info', data
    @embedProvider = new EmbedBoxLinkViewProvider cssClass: 'provider_info', data

    @embedDescription = new EmbedBoxLinkViewDescription
      tagName    : 'a'
      cssClass   : 'preview_text_link'
      attributes :
        href     : data.link_url
        target   : '_blank'
      hasConfig  : options.hasConfig or no
    , data

  viewAppended: JView::viewAppended
  pistachio:->
    """
    {{> @embedTitle}}
    {{> @embedAuthor}}
    {{> @embedProvider}}
    {{> @embedDescription}}
    """

class EmbedBoxLinkViewTitle extends KDView

  constructor:(options={},data)->
    super options, data

    oembed         = data.link_embed
    @originalTitle = oembed?.title

    @hide()  if not oembed?.title? or oembed?.title.trim() is ''

    if options.hasConfig is yes
      @setClass 'has-config'
      @titleInput = new KDInputView
        cssClass     : 'preview_title_input hidden'
        name         : 'preview_title_input'
        defaultValue : oembed.title or ''
        blur         : =>
          @titleInput.hide()
          @$('div.preview_title').html(@getValue()).show()
    else
      @titleInput = new KDCustomHTMLView
        cssClass : 'hidden'
        partial  : oembed.title or ''

    @editIndicator = new KDCustomHTMLView
      tagName   : 'div'
      cssClass  : 'edit-indicator title-edit-indicator'
      pistachio : 'edited'
      tooltip   :
        title   : "Original Content was: #{oembed.original_title or oembed.title or ''}"
    @editIndicator.hide()

  viewAppended:->
    JView::viewAppended.call this
    @editIndicator.show()  if @getData().link_embed?.titleEdited

  getValue:->
    if @options.hasConfig
      @titleInput.getValue()
    else
      @titleInput.getPartial()

  getOriginalValue:-> @originalTitle

  click:(event)->
    return super  unless @options.hasConfig

    event.preventDefault()
    event.stopPropagation()
    @titleInput.show()
    @titleInput.setFocus()
    @$('div.preview_title').hide()
    no

  pistachio:->
    """
      {{> @titleInput}}
      <div class="preview_title">#{@getData().link_embed?.title or @getData().title or @getData().link_url}
        {{> @editIndicator}}
      </div>
    """

class EmbedBoxLinkViewDescription extends KDView

  constructor:(options={},data={})->
    super options, data

    oembed = data.link_embed

    @hide()  if oembed?.description? or oembed?.description.trim() is ''

    @originalDescription = oembed?.description

    if options.hasConfig is yes
      @setClass 'has-config'
      @descriptionInput = new KDInputView
        type         : 'textarea'
        cssClass     : 'description_input hidden'
        name         : 'description_input'
        defaultValue : oembed?.description or ''
        autogrow     : yes
        blur         : =>
          @descriptionInput.hide()
          @$('div.description').html(@getValue()).show()
    else
      @descriptionInput = new KDCustomHTMLView
        cssClass : 'hidden'
        partial : oembed?.description or ''

    @editIndicator = new KDCustomHTMLView
      tagName : 'div'
      cssClass : 'edit-indicator discussion-edit-indicator'
      pistachio : 'edited'
      tooltip :
        title: "Original Content was: <p>#{oembed?.original_description or oembed?.description or ''}</p>"
    @editIndicator.hide()

  getValue:->
    if @options.hasConfig
      @descriptionInput.getValue()
    else
      @descriptionInput.getPartial()

  getOriginalValue:-> @originalDescription

  viewAppended:->
    JView::viewAppended.call this
    if @getData().link_embed?.descriptionEdited
      @editIndicator.show()

  click:(event)->
    return super  unless @options.hasConfig

    event.preventDefault()
    event.stopPropagation()
    @descriptionInput.show()
    @descriptionInput.setFocus()
    @$('div.description').hide()
    no

  pistachio:->
    """
    {{> @descriptionInput}}
    <div class="description #{if @getData().link_embed?.description or @getData().description then '' else 'hidden'}">#{@getData().link_embed?.description or @getData().description or ''}
    {{> @editIndicator}}</div>
    """


class EmbedBoxLinkViewAuthor extends KDView

  constructor:(options,data)->
    super options,data

    @hide()  unless data.link_embed?.author_name?

  viewAppended: JView::viewAppended
  pistachio:->
    """
    written by <a href="#{@getData().link_embed?.author_url or @getData().author_url or '#'}" target="_blank">#{@getData().link_embed?.author_name or @getData().author_name}</a>
    """


class EmbedBoxLinkViewProvider extends KDView

  constructor:(options,data)->
    super options,data

    @hide()  unless data.link_embed?.provider_name?

  viewAppended: JView::viewAppended
  pistachio:->
    """
    for <strong>#{@getData().link_embed?.provider_name or @getData().provider_name or 'the internet'}</strong>#{if (@getData().link_embed?.provider_url or @getData().provider_url) then " at <a href=\"" +(@getData().link_embed?.provider_url or @getData().provider_url)+"\" target=\"_blank\">"+(@getData().link_embed?.provider_display or @getData().provider_display)+'</a>' else ''}
    """
