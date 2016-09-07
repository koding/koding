kd = require 'kd'
JView = require 'app/jview'
proxifyUrl = require 'app/util/proxifyUrl'


module.exports = class EmbedBoxLinkViewImageSwitch extends JView

  { hasClass, addClass, removeClass,
    getDescendantsByClassName, setText } = kd.dom

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

    return  unless (hasClass target, 'preview-link-switch')

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

    # Refresh the image with the new src data
    if imageIndex < oembed.images.length - 1
      imgSrc = oembed.images[imageIndex]?.url
      if imgSrc
        proxiedImage = proxifyUrl imgSrc, width: 100, height: 100, crop: yes, grow: yes
        @getDelegate().embedImage.setSrc proxiedImage
      else
        # imgSrc is undefined - this would be the place for a default
        fallBackImgSrc = "#{location.origin}/a/images/service_icons/Koding.png"
        @getDelegate().embedImage.setSrc fallBackImgSrc

      # Either way, set the imageIndex to the appropriate nr
      # TODO: this sucks:
      @getDelegate().getDelegate().setImageIndex imageIndex

    # When we're at 0/x or x/x, disable the next/prev buttons
    if imageIndex is 0
      @disableButton 'previous'

    else if imageIndex is (oembed.images.length - 1)
      @disableButton 'next'

  pistachio:->
    imageIndex   = @getImageIndex()
    {link_embed} = @getData()
    {images}     = link_embed
    """
    <a class=\"preview-link-switch previous #{if imageIndex is 0 then 'disabled' else ''}\"></a>
    <a class=\"preview-link-switch next #{if imageIndex is images.length then 'disabled' else ''}\"></a>
    """
