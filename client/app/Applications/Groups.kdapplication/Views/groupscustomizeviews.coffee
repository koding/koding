class StaticGroupCustomizeView extends KDView
  constructor:(options,data)->
    super options,data
    @setClass 'group-customize-view'

    @bgSelectView = new StaticGroupBackgroundSelectView
      cssClass  : 'custom-select-background-view'
      delegate  : @
    @bgColorView = new StaticGroupBackgroundColorSelectView
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

          if @customColorChanged
            defaultIndexItem = @bgColorView.thumbsController.selectedItems.first

            if defaultIndexItem
              pickedColor = defaultIndexItem.color.picker.getValue() or 'fff'
              log pickedColor
              @group.setBackgroundImage 'customColor', pickedColor, (err,res)=>
                @saveButton.hideLoader()
                unless err
                  new KDNotificationView
                    title : "Background updated with custom color"
                  @customColorChanged = no

          else if @defaultImageChanged
              defaultIndexItem = @bgSelectView.thumbsController.selectedItems.first

              if defaultIndexItem
                defaultIndex = defaultIndexItem.getData().dataIndex or 0
                @group.setBackgroundImage 'defaultImage', defaultIndex, (err,res)=>
                  @saveButton.hideLoader()
                  unless err
                    new KDNotificationView
                      title : "Background updated to #{defaultIndexItem.getData().title}"
                    @defaultImageChanged = no

          else if @defaultColorChanged
              defaultIndexItem = @bgColorView.thumbsController.selectedItems.first

              if defaultIndexItem
                defaultHex = defaultIndexItem.getData().colorValue or 0
                @group.setBackgroundImage 'defaultColor', defaultHex, (err,res)=>
                  @saveButton.hideLoader()
                  unless err
                    new KDNotificationView
                      title : "Background updated to color #{defaultIndexItem.getData().title}"
                    @defaultColorChanged = no

          else
            # no changes
            @saveButton.hideLoader()

    @attachListeners()

    @fetchGroupData =>
      @bgSelectView.decorateList @group
      @bgColorView.decorateList @group

  fetchGroupData:(callback =->)->
    KD.remote.cacheable @getDelegate().groupEntryPoint, (err,[group],name)=>
      @group = group
      callback group

  attachListeners:->
    @on 'DefaultColorSelected',=>
      @defaultColorChanged = yes
      @customColorChanged = no
      @defaultImageChanged = no
      @bgSelectView.thumbsController.deselectAllItems()

    @on 'DefaultImageSelected',=>
      @defaultImageChanged = yes
      @customColorChanged = no
      @defaultColorChanged = no
      @bgColorView.thumbsController.deselectAllItems()

    @on 'CustomColorSelected',=>
      @customColorChanged = yes
      @defaultImageChanged = no
      @defaultColorChanged = no
      @bgSelectView.thumbsController.deselectAllItems()

  viewAppended:->
    super
    @setTemplate @pistachio()
    @template.update()

  pistachio:->
    """
    {{> @backButton}}
    <h1 class="customize-title">Customize this Group page
    <span class="settings-span">({{> @settingsLink}})</span>
    </h1>
    {{> @bgSelectView}}
    {{> @bgColorView}}
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
        title     : 'Upload an Image'
        url       : '/images/bg/no.jpg'
        thumbUrl  : '/images/bg/th/no.png'
        dataIndex : -1
        type      : 'customImage'
      }
    ]
    for i in [1..5]
      items.push
        title     : "Template ##{i}"
        url       : "/images/bg/bg0#{i}.jpg"
        thumbUrl  : "/images/bg/th/bg0#{i}.png"
        dataIndex : i-1
        type      : 'defaultImage'

    @thumbsController.instantiateListItems items
    @attachListeners()

  attachListeners:->
    @thumbsController.listView.on 'DefaultImageSelected', (view)=>
      @getDelegate().emit 'DefaultImageSelected', view

    @thumbsController.listView.on 'NoImageSelected', (view)=>
      @getDelegate().emit 'NoImageSelected', view

  decorateList:(group={})->
    if group.customize?.background?.customType is 'defaultImage'
      for item in @thumbsController.itemsOrdered
        if item.getData().dataIndex is group.customize.background.customValue
          @thumbsController.selectItem item

    else @thumbsController.deselectAllItems()

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

    @type = @getData().type or 'defaultImage'

    @img = new KDCustomHTMLView
      tagName     : 'img'
      cssClass    : 'custom-image-default'
      attributes  :
        src       : @getData().thumbUrl
        alt       : @getData().title

  click: ->
    # preview live
    if @getData().type is 'defaultImage'
      @getDelegate().emit 'DefaultImageSelected', @
      @getSingleton('staticGroupController').setBackground @type, @getData().url

    else log 'Something weird happened'
  viewAppended:->
      super
      @setTemplate @pistachio()
      @template.update()

  pistachio:->
    """
    {{> @img}}
    {{#(title)}}
    """

##
# COLOR SELECT
##

class StaticGroupBackgroundColorSelectView extends KDView

  constructor:(options,data)->
    super options,data

    @thumbsController = new KDListViewController
      itemClass       : StaticGroupBackgroundColorSelectItemView
      delegate        : @

    @thumbsView = @thumbsController.getView()

    # default items
    items = [
      {title:'Pick a color',colorValue:@utils.getRandomHex(), type:'customColor'}
      {title:'Black',colorValue:'#000000', type:'defaultColor'}
      {title:'White',colorValue:'#ffffff', type:'defaultColor'}
      {title:'Transparent',colorValue:'rgba(0,0,0,0.2)', type:'defaultColor'}
      {title:'Koding',colorValue:'#ff9200', type:'defaultColor'}
      {title:'Rhodamine Red C',colorValue:'#E10098', type:'defaultColor'}
      {title:'876 C',colorValue:'#8B634B', type:'defaultColor'}
      {title:'521 C',colorValue:'#A57FB2', type:'defaultColor'}
      {title:'326 C',colorValue:'#00B2A9', type:'defaultColor'}
      {title:'583 C',colorValue:'#B7BF10', type:'defaultColor'}
    ]

    @thumbsController.instantiateListItems items
    @attachListeners()

  attachListeners:->
    @thumbsController.listView.on 'DefaultColorSelected', (view)=>
      @getDelegate().emit 'DefaultColorSelected', view

    @thumbsController.listView.on 'CustomColorSelected', (view)=>
      @getDelegate().emit 'CustomColorSelected', view

  decorateList:(group={})->
    if group.customize?.background?.customType is 'defaultColor'
      for item in @thumbsController.itemsOrdered
        if item.getData().colorValue is group.customize.background.customValue
          @thumbsController.selectItem item

    if group.customize?.background?.customType is 'customColor'
      for item in @thumbsController.itemsOrdered
        if item.getData().type is 'customColor'
          @thumbsController.selectItem item
          item.decorateCustomColor group.customize.background.customValue

    else @thumbsController.deselectAllItems()


  viewAppended:->
    super
    @setTemplate @pistachio()
    @template.update()

  pistachio:->
    """
    <span class="title">Select a Background</span>
    {{> @thumbsView}}
    """


class StaticGroupBackgroundColorSelectItemView extends KDListItemView
  constructor:(options,data)->
    super options,data

    @setClass 'custom-image-selectitemview color'
    @title = new KDView
      partial : @getData().title

    @type = @getData().type or 'defaultImage'

    if @type is 'defaultColor'
      @color = new KDView
        cssClass : 'custom-color-default'
      @color.$().css backgroundColor : "#{@getData().colorValue}"

    else if @type is 'customColor'
      @color = new StaticGroupBackgroundColorPickerView
        cssClass : 'custom-color-picker'
      ,@getData()

  click: ->
    # preview live
    if @getData().type is 'defaultColor'
      @getDelegate().emit 'DefaultColorSelected', @
      @getSingleton('staticGroupController').setBackground @type, @getData().colorValue

    else if @getData().type is 'customColor'
      @getDelegate().emit 'CustomColorSelected', @
      @getSingleton('staticGroupController').setBackground @type, @color.picker.getValue()
    else log 'Something weird happened'

  decorateCustomColor:(color)->
    @getSingleton('staticGroupController').setBackground @type, color
    @color.decorateCustomColor color or '#ff9200'

  viewAppended:->
      super
      @setTemplate @pistachio()
      @template.update()

  pistachio:->
    """
    {{> @color}}
    {{#(title)}}
    """

class StaticGroupBackgroundColorPickerView extends KDView
  constructor:(options,data)->
    super options,data
    {@type, @colorValue} = @getData()
    @picker         = new KDInputView
      cssClass      : 'color-picker'
      bind          : 'keyup'
      defaultValue  : @colorValue
      keyup         : => @updateColor()
      focus         : => @updateColor()
      blur          : => @updateColor()

    @$().css backgroundColor : @picker.getValue()

  updateColor:->
    @$().css backgroundColor : @picker.getValue()
    @getSingleton('staticGroupController').setBackground @type, @picker.getValue()

  viewAppended:->
    super
    @setTemplate @pistachio()
    @template.update()

  decorateCustomColor:(color)->
    @picker.setValue color
    @$().css backgroundColor : @picker.getValue()

  pistachio:->
    """
    {{> @picker}}
    """