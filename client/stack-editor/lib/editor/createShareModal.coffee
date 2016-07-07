kd = require 'kd'
ContentModal = require 'app/components/contentModal'


createConfirmationModal = (_callback) ->

  modal = new ContentModal
    cssClass     : 'content-modal StackEditor-ShareConfirmationModal'
    overlay      : yes
    title        : 'Sharing Credentials'
    content      : '''
      <h2>Do you really want to share your own credentials?</h2>
      <p>When you share your own credentials with your team,
      they will be able to create resources with it. If you don’t share,
      your team members will need to put their own credentials.</p>
    '''
    buttons      :
      cancel     :
        title    : 'No'
        cssClass : 'kdbutton solid medium'
        callback : -> modal.destroy()
      ok         :
        title    : 'Yes'
        loader   : yes
        cssClass : 'kdbutton solid medium'
        callback : -> _callback yes, modal


module.exports = (_callback) ->

  content = new kd.CustomHTMLView
    partial  : '''
      <div class="background"></div>
      <h1>Share your stack template with your team members</h1>
      <p>When you share your stack template, we will notify team members.</p>
    '''
  content.addSubView checkboxWrapper = new kd.CustomHTMLView
    tagName  : 'p'
    cssClass : 'checkbox-wrapper'
  checkboxWrapper.addSubView checkbox = new kd.CustomCheckBox()
  checkbox.setValue yes
  checkboxWrapper.addSubView label = new kd.CustomHTMLView
    tagName  : 'span'
    partial  : 'Share the credentials I used for this stack with my team.'
    click    : -> checkbox.setValue not checkbox.getValue()

  modal = new ContentModal
    cssClass     : 'content-modal StackEditor-ShareModal'
    overlay      : yes
    width        : 700
    title        : 'Share Your Stack'
    content      : content
    buttons      :
      cancel     :
        title    : 'Cancel'
        cssClass : 'kdbutton solid medium'
        callback : -> modal.destroy()
      share      :
        title    : 'Share With the Team'
        loader   : yes
        cssClass : 'kdbutton solid medium'
        callback : ->
          if checkbox.getValue()
            modal.destroy()
            createConfirmationModal _callback
          else
            _callback no, modal
