getFullnameFromAccount = require '../../util/getFullnameFromAccount'
kd = require 'kd'
whoami = require '../../util/whoami'
isLoggedIn = require '../../util/isLoggedIn'
AvatarStaticView = require './avatarstaticview'
JView = require '../../jview'
MemberMailLink = require '../../members/contentdisplays/membermaillink'


module.exports = class AvatarTooltipView extends JView
  constructor:(options={}, data)->

    super options, data

    origin = options.origin
    name   = getFullnameFromAccount @getData()

    @profileName = new JView
      tagName    : 'a'
      cssClass   : 'profile-name'
      attributes :
        href     : "/#{@getData().profile.nickname}"
        target   : '_blank'
      pistachio  : "<h2>#{name}</h2>"
    , data

    @staticAvatar = new AvatarStaticView
      cssClass  : 'avatar-static'
      noTooltip : yes
      size      :
        width   : 80
        height  : 80
      origin    : origin
    , data


    @likes = new JView
      tagName     : 'a'
      attributes  :
        href      : '#'
      pistachio   : "<cite/>{{#(counts.likes) or 0}} <span>Likes</span>"
      click       : (event)=>
        return if @getData().counts.following is 0
        kd.getSingleton("appManager").tell "Members", "createLikedContentDisplay", @getData()
    , @getData()

    @sendMessageLink = new MemberMailLink {}, @getData()

  viewAppended:->
    super()
    @setTemplate @pistachio()
    @template.update()

  click:(event)->
    # @getDelegate()?.getTooltip().hide()


  updateData:(data={})->

    # lazy loading data is spoonfed to the individual views
    @setData data

    @profileName.setData data
    @profileName.render()

    @followers.setData data
    @following.setData data
    @likes.setData data
    @sendMessageLink.setData data

    @followers.render()
    @following.render()
    @likes.render()
    @sendMessageLink.render()

  pistachio:->
    """
    <div class="leftcol">
      {{> @staticAvatar}}
      {{> @followButton}}
    </div>
    <div class="rightcol">
      {{> @profileName}}
      <div class="profilestats">
          <div class="fers">
            {{> @followers}}
          </div>
          <div class="fing">
            {{> @following}}
          </div>
           <div class="liks">
            {{> @likes}}
          </div>
          <div class='contact'>
            {{> @sendMessageLink}}
          </div>
        </div>
    </div>
    """


