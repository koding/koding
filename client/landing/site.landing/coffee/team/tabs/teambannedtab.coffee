kd = require 'kd'

MainHeaderView     = require './../../core/mainheaderview'

module.exports = class TeamBannedTab extends kd.TabPaneView



  constructor: (options = {}, data) ->

    super options, data

    @header = new MainHeaderView
      cssClass : 'team'
      navItems : [
        { title : 'Blog',        href : 'http://blog.koding.com',           name : 'blog' }
        { title : 'Koding Home', href : "http://#{kd.config.domains.main}", name : 'koding' }
      ]


  pistachio: ->

    """
    {{> @header }}
    <div class="TeamsModal TeamsModal--banned">
      <h4>Your access is revoked!</h4>
      <h5>We are sorry, one of the administrators has banned you from the team <a href='/'>#{kd.config.groupName}</a>.</h5>
      <p>If you think this is due to an error, please contact the team admins.</p>
    </div>
    """
