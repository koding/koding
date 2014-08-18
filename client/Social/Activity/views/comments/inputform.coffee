class CommentInputForm extends KDView

  constructor: (options = {}, data) ->

    options.type       or= 'new-comment'
    options.cssClass     = KD.utils.curry 'item-add-comment-box', options.cssClass
    options.showAvatar  ?= yes

    super options, data

    @input          = new KDHitEnterInputView
      type          : 'textarea'
      delegate      : this
      placeholder   : 'Type your comment and hit enter...'
      autogrow      : yes
      validate      :
        rules       :
          required  : yes
          maxLength : 2000
        messages    :
          required  : 'Please type a comment...'
      callback      : @bound 'enter'

    @input.on 'focus', @bound 'inputFocused'
    @input.on 'blur', @bound 'inputBlured'


  enter: (value) ->

    @emit 'Submit', value, (new Date).getTime()

    @input.setValue ''
    @input.resize()
    @input.setFocus()

    kallback = =>

      KD.mixpanel 'Comment activity, click', value.length

    KD.requireMembership
      callback  : kallback
      onFailMsg : 'Login required to post a comment!'
      tryAgain  : yes
      groupName : KD.getGroup().slug


  mention: (username) ->

    value = @input.getValue()

    @setFocus()

    @input.setValue \
      if value.indexOf("@#{username}") >= 0 then value
      else if value.length is 0 then "@#{username} "
      else "#{value} @#{username} "


  setFocus: ->

    @input.setFocus()
    KD.singleton('windowController').setKeyView @input


  inputFocused: ->

    @emit 'Focused'
    KD.mixpanel 'Comment activity, focus'


  inputBlured: ->

    return  unless @input.getValue() is ''
    @emit 'Blured'


  viewAppended: ->

    if @getOption 'showAvatar'
      @addSubView new AvatarStaticView
        size    :
          width : 38
          height: 38
      , KD.whoami()

    @addSubView @input
