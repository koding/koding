module.exports = class SubscribeFormView extends KDFormViewWithFields

  constructor : (options = {}) ->

    options.cssClass = KD.utils.curry "subscribe-form", options.cssClass

    options.fields   =
      description    :
        itemClass    : KDCustomHTMLView
        partial      : 'Sign up and get notified about upcoming events'
        tagname      : 'h4'
      thankYou       :
        itemClass    : KDCustomHTMLView
        partial      : "Thanks, we'll let you know!"
      email          :
        type         : 'email'
        placeholder  : 'your@email.com'

    options.buttons  =
      submit         :
        title        : 'SIGN UP'
        style        : 'solid'
        type         : 'submit'
        loader       : yes

    options.callback = @bound 'subscribe'

    super options

    @fields['thankYou'].hide()

    @on 'subscribeSuccess', @bound 'thankYou'


  thankYou : ->

    {email, thankYou} = @fields

    email.hide()
    @buttonField.hide()
    thankYou.show()


  subscribe : ->

    {submit} = @buttonField.buttons

    submit.showLoader()

    data = @serializeFormData()

    jQuery.ajax
      url         : "/-/emails/subscribe"
      type        : 'POST'
      data        : data
      success     : => @emit 'subscribeSuccess'
      error       : => @emit 'subscribeError'
      complete    : => submit.hideLoader()
