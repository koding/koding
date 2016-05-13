kd = require 'kd'
CredentialForm = require './credentialform'
copyToClipboard = require 'app/util/copyToClipboard'

module.exports = class KDCredentialForm extends CredentialForm

  constructor: (options, data) ->

    super options, data

    @codeBlock = new kd.CustomHTMLView
      tagName  : 'code'
      cssClass : 'block'
      partial  : '''
        <div>export KONTROLURL=http://52.200.100.228:8090/kontrol/kite; curl -sL https://kodi.ng/d/kd | bash -s 9c9702af</div>
        <cite>Ctrl + C</cite>
      '''
      click    : ->
        copyToClipboard @getElement().querySelector 'div'


  pistachio: ->

    { title } = @getOptions()

    """
      <h3 class='top-header'>#{title}:</h3>
      <div class='selection-container'>
        {{> @selectionLabel}}
        {{> @selection}}
      </div>
      {{> @createNew}}
      <div class='form-container'>
        <h3 class='new-credential-header'>
          New #{title}:
          {{> @cancelNew}}
        </h3>
        <article>
          <p>
            <code>kd</code>  is a command line program that allows you to use your local
            IDE with your VMs. Copy and paste the command below into your terminal.
          </p>
          {{> @codeBlock}}
          <p>
            Once installed, you can use <code>kd list</code> to list your Koding VMs and <code>kd mount</code> to mount your VM to a local folder in your computer.
            For detailed instructions: <a href="https://www.koding.com/docs/connect-your-machine" target="_blank">https://www.koding.com/docs/connect-your-machine</a>
          </p>
        </article>
        {{> @form}}
      </div>
    """
