RegisterInlineForm = require './../login/registerform'

module.exports = class HomeRegisterForm extends RegisterInlineForm

  constructor: ->

    super

    @gravatarInfo?.destroy()
    @gravatarInfo = new KDInputView
      type            : 'hidden'
      name            : 'gravatar'

    @email.setOption 'stickyTooltip', yes
    @password.setOption 'stickyTooltip', yes

    @email.input.on    'focus', @bound 'handleFocus'
    @password.input.on 'focus', @bound 'handleFocus'
    @email.input.on    'blur',  => @fetchGravatarInfo @email.input.getValue()

    KD.singletons.router.on 'RouteInfoHandled', =>
      @email.icon.unsetTooltip()
      @password.icon.unsetTooltip()

    @on 'gravatarInfoFetched', =>
      @gravatarInfoFetched = yes

  handleFocus: -> @setClass 'focused'


  handleBlur: -> @unsetClass 'focused'


  fetchGravatarInfo : (email) ->
    @gravatarInfoFetched = no

    $.ajax
      url         : "/FetchGravatarInfo"
      data        :
        email     : email
      type        : 'POST'
      xhrFields   : withCredentials : yes
      success     : (data) =>
        data      = JSON.stringify data
        @gravatarInfo.setValue(data)
        @emit 'gravatarInfoFetched', data

      error       : (xhr) ->
        {responseText} = xhr


  pistachio : ->

    """
    <section class='clearfix'>
      {{> @gravatarInfo}}
      <div class='fl email'>{{> @email}}</div>
      <div class='fl password'>{{> @password}}</div>
      <div class='fl submit'>{{> @button}}</div>
    </section>
    """