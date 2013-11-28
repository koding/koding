class EmbedBoxLinkViewImageSwitch extends KDView

  { hasClass, addClass, removeClass,
    getDescendantsByClassName, setText } = KD.dom

  constructor:(options={}, data)->
    super options, data

    @hide()  if (not data.link_embed.images? or\
                 data.link_embed.images.length < 2)

    @imageIndex = 0

  getImageIndex: -> @imageIndex
  setImageIndex: (@imageIndex) ->

  getButton: (dir) ->
    (getDescendantsByClassName @getElement(), dir)[0]

  disableButton: (dir) ->
    addClass @getButton(dir), 'disabled'

  enableButton: (dir) ->
    removeClass @getButton(dir), 'disabled'

  click:(event)->

    event.preventDefault()
    event.stopPropagation()

    oembed = @getData().link_embed
    
    return  unless oembed?.images?

    { target } = event

    return  unless (hasClass target, 'preview_link_switch')

    imageIndex = @getImageIndex()

    # There are 1+ more images beyond the current one
    if (hasClass target, 'next') and\
       oembed.images.length - 1 > imageIndex

      imageIndex++
      @setImageIndex imageIndex
      @enableButton 'previous'

    # There are 1+ more images before the current one
    else if (hasClass target, 'previous') and imageIndex > 0

      imageIndex--
      @setImageIndex imageIndex
      @enableButton 'next'

    # update the thumb "page number":
    [pageNumber] = getDescendantsByClassName @getElement(), 'thumb_nr'
    setText pageNumber, imageIndex + 1

    # Refresh the image with the new src data
    if imageIndex < oembed.images.length - 1
      imgSrc = oembed.images[imageIndex]?.url
      if imgSrc
        proxiedImage = @utils.proxifyUrl imgSrc, width: 100, height: 100, crop: yes
        @getDelegate().embedImage.setSrc proxiedImage
      else
        # imgSrc is undefined - this would be the place for a default
        fallBackImgSrc = 'https://koding.com/images/service_icons/Koding.png'
        @getDelegate().embedImage.setSrc fallBackImgSrc

      # Either way, set the imageIndex to the appropriate nr
      # TODO: this sucks:
      @getDelegate().getDelegate().setImageIndex imageIndex

    else
      # imageindex out of bounds - displaying default image
      # (first in the images array) the pistachio will also take care
      # of this

      defaultImgSrc = oembed.images[0]?.url
      @getDelegate().embedImage.setSrc defaultImgSrc

    # When we're at 0/x or x/x, disable the next/prev buttons
    if imageIndex is 0
      @disableButton 'previous'

    else if imageIndex is (oembed.images.length - 1)
      @disableButton 'next'

  viewAppended: JView::viewAppended

  pistachio:->
    """
    <a class="preview_link_switch previous #{if @getImageIndex() is 0 then "disabled" else ""}">&lt;</a><a class="preview_link_switch next #{if @getImageIndex() is data?.link_embed?.images?.length then "disabled" else ""}">&gt;</a>
    <div class="thumb_count"><span class="thumb_nr">#{@getImageIndex()+1 or "1"}</span>/<span class="thumb_all">#{@getData()?.link_embed?.images?.length}</span> <span class="thumb_text">Thumbs</span></div>
    """
