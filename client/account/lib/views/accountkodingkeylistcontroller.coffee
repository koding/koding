kd                        = require 'kd'
AccountListViewController = require '../controllers/accountlistviewcontroller'
remote                    = require('app/remote').getInstance()


module.exports = class AccountKodingKeyListController extends AccountListViewController

  constructor:(options, data)->

    options.noItemFoundText = """
    <h2>EXPERIMENTAL</h2>
    <p>
      You have no Koding keys. Koding keys are used to authenticate external
      kites (Koding applications running on other machines). To get your keys listed here you need to download and install kd tool:
    </p>

    For OS X run the following command in Terminal:
    <code>$ brew install "https://kd-tool.s3.amazonaws.com/kd.rb"</code>

    For Ubuntu/Debian install the following package:
    <code><a href="https://kd-tool.s3.amazonaws.com/kd-latest-linux.deb">https://kd-tool.s3.amazonaws.com/kd-latest-linux.deb</a></code>

    and then register your machine with
    <code>$ kd register</code>
    """
    options.cssClass = "koding-keys"
    super options, data


  loadView: ->
    super
    @removeAllItems()
    @showLazyLoader no
    remote.api.JKodingKey.fetchAll {}, (err, keys) =>
      if err then kd.warn err
      else
        @instantiateListItems keys
        @hideLazyLoader()
