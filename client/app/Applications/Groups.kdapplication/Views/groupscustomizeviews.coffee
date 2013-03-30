class StaticGroupCustomizeView extends KDView
  constructor:(options,data)->
    super options,data
    @setClass 'group-customize-view'

    @bgSelectView = new StaticGroupBackgroundSelectView
      cssClass  : 'custom-select-background-view'
      delegate  : @
    @bgUploadView = new StaticGroupBackgroundUploadView
      cssClass  : 'custom-select-background-upload-view'

    @settingsLink = new CustomLinkView
      title     : 'Looking for Group Settings?'
      href      : '#'
      cssClass  : 'settings-link'
      click     : =>
        @getSingleton('lazyDomController')?.openPath "/#{@getDelegate().groupEntryPoint}/Activity"

    @backButton = new KDButtonView
      title     : 'Back'
      cssClass  : 'back-button modal-cancel'
      callback  : =>
        @getDelegate().groupContentWrapperView.unsetClass 'edit'

    @saveButton = new KDButtonView
      title     : 'Save Changes'
      cssClass  : 'save-button clean-gray'
      loader    :
        color   : '#444'
        diameter : 12
      callback :=>
        if @group

          @saveButton.showLoader()

          if @noImageChanged
            @group.setBackgroundImage 'none', null, (err,res)=>
              @saveButton.hideLoader()
              unless err
                new KDNotificationView
                  title : "Background Image removed"
                @noImageChanged = no

          if @defaultImageChanged
              defaultIndexItem = @bgSelectView.thumbsController.selectedItems.first

              if defaultIndexItem
                defaultIndex = defaultIndexItem.getData().dataIndex or 0
                @group.setBackgroundImage 'default', defaultIndex, (err,res)=>
                  @saveButton.hideLoader()
                  unless err
                    new KDNotificationView
                      title : "Background updated to #{defaultIndexItem.getData().title}"
                    @defaultImageChanged = no

          else
            # no changes
            @saveButton.hideLoader()

    @attachListeners()
    @fetchGroupData =>
      @bgSelectView.decorateList @group

  fetchGroupData:(callback =->)->
    KD.remote.cacheable @getDelegate().groupEntryPoint, (err,[group],name)=>
      @group = group
      callback group

  attachListeners:->
    @on 'DefaultImageSelected',=>
      @defaultImageChanged = yes
      @noImageChanged = no

    @on 'NoImageSelected',=>
      @noImageChanged = yes
      @defaultImageChanged = no

  viewAppended:->
    super
    @setTemplate @pistachio()
    @template.update()

  pistachio:->
    """
    {{> @backButton}}
    <h1 class="customize-title">Customize this Group page
    <span>({{> @settingsLink}})</span>
    </h1>
    {{> @bgSelectView}}
    {{> @bgUploadView}}
    {{> @saveButton}}
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

    @thumbsController  = new KDListViewController
      itemClass       : StaticGroupBackgroundSelectItemView
      delegate        : @

    @thumbsView = @thumbsController.getView()

    # default items
    items = [
      {
        title     : 'No Image'
        url       : '/images/bg/no.jpg'
        thumbUrl  : '/images/bg/th/no.png'
        dataIndex : -1
        type      : 'none'
      }
    ]
    for i in [1..5]
      items.push
        title     : "Template ##{i}"
        url       : "/images/bg/bg0#{i}.jpg"
        thumbUrl  : "/images/bg/th/bg0#{i}.png"
        dataIndex : i-1
        type      : 'default'

    @thumbsController.instantiateListItems items
    @attachListeners()

  attachListeners:->
    @thumbsController.listView.on 'DefaultImageSelected', (view)=>
      @getDelegate().emit 'DefaultImageSelected', view

    @thumbsController.listView.on 'NoImageSelected', (view)=>
      @getDelegate().emit 'NoImageSelected', view

  decorateList:(group={})->
    if group.customize?.background?.imageType is 'default'
      for item in @thumbsController.itemsOrdered
        if item.getData().dataIndex is group.customize.background.defaultImage
          @thumbsController.selectItem item

    if group.customize?.background?.imageType is 'none'
      for item in @thumbsController.itemsOrdered
        if item.getData().dataIndex is -1
          @thumbsController.selectItem item

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


  click: ->
    # preview live
    if @getData().type is 'default'
      @getDelegate().emit 'DefaultImageSelected', @
      @getSingleton('staticGroupController').setBackground @getData().url
    else if @getData().type is 'none'
      @getDelegate().emit 'NoImageSelected', @
      @getSingleton('staticGroupController').removeBackground()
    else log 'Something weird happened'
  viewAppended:->
      super
      @setTemplate @pistachio()
      @template.update()

  pistachio:->
    """
    {{#(title)}}
    {{> @img}}
    """
