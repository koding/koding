class GuidesLinksView extends JView
  constructor: (options = {}, data) ->

    options.cssClass = KD.utils.curry 'guides-links', options.cssClass

    super options, data

    @createLinks()

  createLinks: ->

    @ssh = new CustomLinkView
      cssClass : 'ssh'
      title    : 'ssh'
      href     : 'http://learn.koding.com/guides/ssh-into-your-vm/'
      target   : '_blank'

    @sudo = new CustomLinkView
      cssClass : 'sudo'
      title    : 'sudo'
      href     : 'http://learn.koding.com/faq/what-is-my-sudo-password/'
      target   : '_blank'

    @mySQL = new CustomLinkView
      cssClass : 'mysql'
      title    : 'mySQL'
      href     : 'http://learn.koding.com/guides/installing-mysql/'
      target   : '_blank'

    @nodeJS = new CustomLinkView
      cssClass : 'nodejs'
      title    : 'NodeJS'
      href: 'http://learn.koding.com/guides/getting-started-nodejs/'
      target   : '_blank'

    @apache = new CustomLinkView
      cssClass : 'apache'
      title    : 'apache'
      href     : 'http://learn.koding.com/categories/apache/'
      target   : '_blank'


  pistachio: ->
    """
    {{> @ssh}}, {{> @sudo}}, {{> @mySQL}}, {{> @nodeJS}}, {{> @apache}}
    """


