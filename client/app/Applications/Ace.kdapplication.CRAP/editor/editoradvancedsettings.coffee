class EditorAdvancedSettings_ContextMenu extends KDContextMenuTreeViewController

  itemClass: (options, data) ->

    item = new (@getOptions().subItemClass ? KDTreeItemView) options, data
    switch data.type
      when 'switch'
        item.addSubView new KDRySwitch
          type: 'checkbox'
          defaultValue: data.default?()
          callback: (state)->
            data.callback? state
        item
      when 'input'
        item.addSubView input = new KDInputView
          defaultValue  : data.default?()
        input.registerListener KDEventTypes : 'Keyup', listener : @, callback :->
          value = input.getValue()
          if isNaN value then input.setValue data.default?() else data.callback? value
        item
      when 'select'
        item.addSubView selectBox = new KDSelectBox
          selectOptions : if data.editorOption is 'mode' then availableModes else if data.editorOption is 'theme' then availableThemes
          defaultValue  : data.default?()
          callback: (value)->
            data.callback? value
        item
      else
        super

class EditorAdvancedSettings_ContextMenu extends KDContextMenuTreeViewController

  itemClass: (options, data) ->

    switch data.type
      when 'switch'
        item = new (@getOptions().subItemClass ? KDTreeItemView) options, data
        item.addSubView new KDRySwitch
          type: 'checkbox'
          defaultValue: data.default?()
          callback: (state)->
            data.callback? state
        item
      when 'softwrap'
        item = new (@getOptions().subItemClass ? KDTreeItemView) options, data
        softWrapInputHolder = new Editor_BottomBar_Section
        softWrapInput = new Editor_BottomBar_Select
          selectOptions: [
              value: 'off'
              title: 'Off'
            ,
              value: 40
              title: '40 chars'
            ,
              value: 80
              title: '80 chars'
            ,
              value: 'free'
              title: 'Free'
            ]
          defaultValue: data.default()

        item.addSubView softWrapInputHolder
        softWrapInputHolder.addSubView softWrapInput
        
        @listenTo
          KDEventTypes: 'change'
          listenedToInstance: softWrapInput
          callback: (pubInst, event) ->
            data.callback softWrapInput.getValue()
        item
      when 'element'
        item = new (@getOptions().subItemClass ? KDTreeItemView) options, data
        item.addSubView data.element
        data.element.input?.setValue data.default?()
        item
      else
        super