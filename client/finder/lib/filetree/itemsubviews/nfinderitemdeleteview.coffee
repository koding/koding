kd = require 'kd'
KDButtonView = kd.ButtonView
KDCustomHTMLView = kd.CustomHTMLView
KDLabelView = kd.LabelView

module.exports = class NFinderItemDeleteView extends kd.View

  constructor: ->

    super
    @setClass 'delete-container'
    @button = new KDButtonView
      title     : 'Delete'
      style     : 'clean-red'
      callback  : => @emit 'FinderDeleteConfirmation', yes

    @cancel = new KDCustomHTMLView
      tagName   : 'a'
      attributes:
        href    : '#'
        title   : 'Cancel'
      cssClass  : 'cancel'
      click     : => @emit 'FinderDeleteConfirmation', no

    @label = new KDLabelView
      title     : 'Are you sure?'

  viewAppended: ->

    super
    @button.$().focus()

  pistachio: ->

    '''
    {{> @label}}
    {{> @button}}
    {{> @cancel}}
    '''

  keyDown: (event) ->

    switch event.which
      when 27 #esc
        @emit 'FinderDeleteConfirmation', no
        no
      when 9
        unless @button.$().is(':focus')
          @button.$().focus()
          no
