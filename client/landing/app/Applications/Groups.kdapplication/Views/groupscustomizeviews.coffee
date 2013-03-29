class StaticGroupCustomizeView extends KDView
  constructor:(options,data)->
    super options,data
    @setClass 'group-customize-view'

    @bgSelectView = new StaticGroupBackgroundSelectView
      cssClass : 'custom-select-background-view'

    @bgUploadView = new StaticGroupBackgroundUploadView
      cssClass : 'custom-select-background-upload-view'

    @settingsLink = new CustomLinkView
      title : 'Change Group Settings'
      href : '#'
      click :=>
        @getSingleton('lazyDomController')?.openPath "/#{@getDelegate().groupEntryPoint}/Activity"

  viewAppended:->
    super
    @setTemplate @pistachio()
    @template.update()

  pistachio:->
    """
    <h1 class="customize-title">Customize this Group page</h1>
    {{> @bgSelectView}}
    {{> @bgUploadView}}
    {{> @settingsLink}}
    """


class StaticGroupBackgroundUploadView extends KDView
  constructor:(options,data)->
    super options,data

  viewAppended:->
    super
    @setTemplate @pistachio()
    @template.update()

  pistachio:->
    """
    <span class="title">Upload a Background</span>
    """


class StaticGroupBackgroundSelectView extends KDView
  constructor:(options,data)->
    super options,data
    @thumbsContoller  = new KDListViewController
      itemClass       : StaticGroupBackgroundSelectItemView
      delegate        : @
    @thumbsView = @thumbsContoller.getView()

    # default items
    items = []
    for i in [1..5]

      items.push
        title     : "Template ##{i}"
        url       : "/images/bg/bg0#{i}.jpg"
        thumbUrl  : "/images/bg/th/bg0#{i}.png"


    @thumbsContoller.instantiateListItems items

  viewAppended:->
    super
    @setTemplate @pistachio()
    @template.update()

  pistachio:->
    """
    <span class="title">Select a Background</span>
    {{> @thumbsView}}
    """

class StaticGroupBackgroundSelectItemView extends KDListItemView
  constructor:(options,data)->
    super options,data

    @setClass 'custom-image-selectitemview'
    @title = new KDView
      partial : @getData().title

    @img = new KDCustomHTMLView
      tagName     : 'img'
      cssClass    : 'custom-image-default'
      attributes  :
        src       : @getData().thumbUrl
        alt       : @getData().title
      click       : =>
        @getSingleton('staticGroupController').setBackground @getData().url

    console.log @getData()
  viewAppended:->
      super
      @setTemplate @pistachio()
      @template.update()

  pistachio:->
    """
    {{#(title)}}
    {{> @img}}
    """
