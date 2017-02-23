kd = require 'kd'
particlejson = require './particlejson'
require 'particles.js'
require './style/deleteaccountoverlay.styl'

module.exports = class DeleteAccountOverlay extends kd.OverlayView

  constructor: (options = {}, data) ->

    options.cssClass = 'delete-account-overlay'
    options.domId = 'particles'
    options.isRemovable = no

    super options, data

    window.particlesJS 'particles', particlejson

    @addSubView new kd.CustomHTMLView
      cssClass: 'content'
      partial: '''
          <img class="spacestation" src='/a/images/space_station.png'  srcset='/a/images/space_station.png 1x, /a/images/space_station@2x.png 2x' />
          <img class="disconnected" src='/a/images/disconnected.png'  srcset='/a/images/disconnected.png 1x, /a/images/disconnected@2x.png 2x' />
          <div class='content-header'>
            We will miss you!
          </div>
          <div class='content-description'>
            It's been a pleasure to have you at Koding. Hope to see you soon.
          </div>
        '''
