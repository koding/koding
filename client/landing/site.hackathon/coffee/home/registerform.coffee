RegisterInlineForm = require './../login/registerform'

module.exports = class HomeRegisterForm extends RegisterInlineForm

  constructor: ->

    super

    @email.setOption 'stickyTooltip', yes
    @username.setOption 'stickyTooltip', yes

    @email.input.on    'focus', @bound 'handleFocus'
    @username.input.on 'focus', @bound 'handleFocus'

    KD.singletons.router.on 'RouteInfoHandled', =>
      @email.icon.unsetTooltip()
      @username.icon.unsetTooltip()


  handleFocus: -> @setClass 'focused'


  handleBlur: -> @unsetClass 'focused'


  pistachio : ->

    """
    <section class='clearfix'>
      <div class='fl email'>{{> @email}}</div>
      <div class='fl username'>{{> @username}}</div>
      <div class='fl submit'>{{> @button}}</div>
    </section>
    """