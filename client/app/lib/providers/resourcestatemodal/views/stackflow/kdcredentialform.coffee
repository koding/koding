kd = require 'kd'
JView = require 'app/jview'
CredentialForm = require './credentialform'
copyToClipboard = require 'app/util/copyToClipboard'
getCopyToClipboardShortcut = require 'app/util/getCopyToClipboardShortcut'

module.exports = class KDCredentialForm extends CredentialForm

  getScrollableContent: ->

    { kdCmd } = @getData()
    codeBlock = new kd.CustomHTMLView
      tagName  : 'code'
      cssClass : 'block'
      partial  : """
        <div>#{kdCmd}</div>
        <cite>#{getCopyToClipboardShortcut()}</cite>
      """
      click    : ->
        copyToClipboard @getElement().querySelector 'div'

    return new JView {
      pistachioParams : { codeBlock, form : @form }
      pistachio       : '''
        <article>
          <p>
            <code>kd</code>  is a command line program that allows you to use your local
            IDE with your VMs. Copy and paste the command below into your terminal.
          </p>
          {{> codeBlock}}
          <p>
            Once installed, you can use <code>kd list</code> to list your Koding VMs and <code>kd mount</code> to mount your VM to a local folder in your computer.
            For detailed instructions: <a href="https://www.koding.com/docs/connect-your-machine" target="_blank">https://www.koding.com/docs/connect-your-machine</a>
          </p>
        </article>
        {{> form}}
      '''
    }
