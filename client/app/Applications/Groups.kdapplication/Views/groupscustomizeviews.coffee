class StaticGroupCustomizeView extends KDView
  constructor:(options,data)->
    super options,data

    @bgSelectView = new StaticGroupBackgroundSelectView

  viewAppended:->
    super
    @setTemplate @pistachio()
    @template.update()

  pistachio:->
    """
    {{> @bgSelectView}}
    """

class StaticGroupBackgroundSelectView extends KDView
  constructor:(options,data)->
    super options,data
    @thumbsContoller = new KDListViewController
      itemClass : StaticGroupBackgroundSelectItemView
    @thumbsView = @thumbsContoller.getView()

    # default items

    items = []
    for i in [1..5]
      items.push

        title : "Template ##{i}"
        url : "/images/bg/bg0#{i}.jpg"
        thumbUrl : "/images/bg/th/bg0#{i}.png"



    @thumbsContoller.instantiateListItems items

  viewAppended:->
    super
    @setTemplate @pistachio()
    @template.update()

  pistachio:->
    """
    {{> @thumbsView}}
    """

class StaticGroupBackgroundSelectItemView extends KDListItemView
  constructor:(options,data)->
    super options,data

    @setClass 'custom-image-selectitemview'
    @title = new KDView
      partial : @getData().title

    @img = new KDCustomHTMLView
      tagName : 'img'
      cssClass : 'custom-image-default'
      attributes :
        src : @getData().thumbUrl
        alt : ''
      click:=>
        @getSingleton('staticGroupController').setBackground @getData().url

    console.log @getData()
  viewAppended:->
      super
      @setTemplate @pistachio()
      @template.update()

  pistachio:->
    """
    {{> @img}}
    THIS IS AN ITEM {{> @title}}

    """
