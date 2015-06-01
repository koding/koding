kd                = require 'kd'
KDListItemView    = kd.ListItemView
KDCustomHTMLView  = kd.CustomHTMLView
JView             = require 'app/jview'


module.exports = class ActivityBaseListItemView extends KDListItemView

  JView.mixin @prototype

  constructor: (options = {}, data) ->

    options.showMore  ?= yes

    super options, data


  checkIfItsTooTall: ->

    { showMore, showMoreWrapper, showMoreMarkClass } = @getOptions()

    return unless showMore

    article          = @$(showMoreWrapper)[0]
    { scrollHeight } = article
    { height }       = article.getBoundingClientRect()

    if scrollHeight > height

      @showMore?.destroy()
      list = @getDelegate()
      @showMore = new KDCustomHTMLView
        tagName  : 'a'
        cssClass : 'show-more'
        href     : '#'
        partial  : 'Show more'
        click    : ->
          article.style.maxHeight = "#{scrollHeight}px"
          article.classList.remove 'tall'

          kd.utils.wait 500, -> list.emit 'ItemWasExpanded'

          @destroy()

      article.classList.add 'tall'

      @addSubView @showMore, showMoreMarkClass
