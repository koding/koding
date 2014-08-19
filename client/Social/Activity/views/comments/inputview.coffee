class CommentInputView extends ActivityInputView

  constructor: (options = {}, data) ->

    options.cssClass = KD.utils.curry 'item-add-comment-box', options.cssClass
    options.bind or= "focus blur"

    super options, data


  forceBlur: -> no


  focus: ->

    super

    @emit 'focus'


  blur: ->

    super

    @emit 'blur'

