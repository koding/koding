kd = require 'kd'

CredentialForm = require './credentialform'
getKdCmd = require 'app/util/getKdCmd'
copyToClipboard = require 'app/util/copyToClipboard'
getCopyToClipboardShortcut = require 'app/util/getCopyToClipboardShortcut'

module.exports = class KDCredentialForm extends CredentialForm

  getScrollableContent: ->

    @codeBlock = new kd.View
      tagName   : 'code'
      cssClass  : 'block'
      pistachio : """
        {{#(kdCmd)}}
        <cite>#{getCopyToClipboardShortcut()}</cite>
      """
      click    : ->
        copyToClipboard @getElement().querySelector 'span'
    , {
      initial  : yes
      kdCmd    : 'Generating install url...'
    }

    return new kd.View {
      pistachioParams : { @codeBlock, @form }
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

  onCreateNew: ->

    if @codeBlock.getData().initial
      getKdCmd (err, kdCmd) =>
        @codeBlock.setData { kdCmd, initial: no }  unless err

    super
