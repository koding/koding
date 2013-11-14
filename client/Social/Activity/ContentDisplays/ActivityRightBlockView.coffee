class ActivityRightBlock extends KDCustomHTMLView
  constructor:(options={}, data)->
    options.cssClass      = "activity-right-block"

    super options, data

  viewAppended:->
    @addSubView activities = new JView
      cssClass      : "activity-right-box"
      pistachio     :
        """
          <h3>Activity Feed <i class="cog-icon"></i></h3>
          <div class="activities">
            <div class="activity">
              <a class="avatarview" style="width: 28px; height: 28px; background-image: url(http://gravatar.com/avatar/934de9c1bb70346d4141722fb35c78b6?size=28&amp;d=http%3A%2F%2Flocalhost%3A3020%2Fimages%2Fdefaultavatar%2Fdefault.avatar.65.png);"></a>
              <span class="activity-content"><a href="#">Emre</a> likes <a href="#">Sinan</a>'s status</span>
            </div>
            <div class="activity">
              <a class="avatarview" style="width: 28px; height: 28px; background-image: url(http://gravatar.com/avatar/934de9c1bb70346d4141722fb35c78b6?size=28&amp;d=http%3A%2F%2Flocalhost%3A3020%2Fimages%2Fdefaultavatar%2Fdefault.avatar.65.png);"></a>
              <span class="activity-content"><a href="#">Emre</a> likes <a href="#">Sinan</a>'s status</span>
            </div>
            <div class="activity">
              <a class="avatarview" style="width: 28px; height: 28px; background-image: url(http://gravatar.com/avatar/934de9c1bb70346d4141722fb35c78b6?size=28&amp;d=http%3A%2F%2Flocalhost%3A3020%2Fimages%2Fdefaultavatar%2Fdefault.avatar.65.png);"></a>
              <span class="activity-content"><a href="#">Emre</a> likes <a href="#">Sinan</a>'s status</span>
            </div>
            <div class="activity">
              <a class="avatarview" style="width: 28px; height: 28px; background-image: url(http://gravatar.com/avatar/934de9c1bb70346d4141722fb35c78b6?size=28&amp;d=http%3A%2F%2Flocalhost%3A3020%2Fimages%2Fdefaultavatar%2Fdefault.avatar.65.png);"></a>
              <span class="activity-content"><a href="#">Emre</a> likes <a href="#">Sinan</a>'s status</span>
            </div>
          </div>
        """

    @addSubView friends = new JView
      cssClass      : "activity-right-box"
      pistachio     :
        """
          <h3>Friends</h3>
          <div class="friends">
            <div class="friend online">
              <a class="avatarview" style="width: 28px; height: 28px; background-image: url(http://gravatar.com/avatar/934de9c1bb70346d4141722fb35c78b6?size=28&amp;d=http%3A%2F%2Flocalhost%3A3020%2Fimages%2Fdefaultavatar%2Fdefault.avatar.65.png);"></a>
              <span class="friend-name">Emre Durmuş</span>
              <i></i>
            </div>
            <div class="friend online">
              <a class="avatarview" style="width: 28px; height: 28px; background-image: url(http://gravatar.com/avatar/934de9c1bb70346d4141722fb35c78b6?size=28&amp;d=http%3A%2F%2Flocalhost%3A3020%2Fimages%2Fdefaultavatar%2Fdefault.avatar.65.png);"></a>
              <span class="friend-name">Emre Durmuş</span>
                <i></i>
            </div>
            <div class="friend">
              <a class="avatarview" style="width: 28px; height: 28px; background-image: url(http://gravatar.com/avatar/934de9c1bb70346d4141722fb35c78b6?size=28&amp;d=http%3A%2F%2Flocalhost%3A3020%2Fimages%2Fdefaultavatar%2Fdefault.avatar.65.png);"></a>
              <span class="friend-name">Emre Durmuş</span>
              <i></i>
            </div>
            <div class="friend">
              <a class="avatarview" style="width: 28px; height: 28px; background-image: url(http://gravatar.com/avatar/934de9c1bb70346d4141722fb35c78b6?size=28&amp;d=http%3A%2F%2Flocalhost%3A3020%2Fimages%2Fdefaultavatar%2Fdefault.avatar.65.png);"></a>
              <span class="friend-name">Emre Durmuş</span>
              <i></i>
            </div>
            <div class="friend">
              <a class="avatarview" style="width: 28px; height: 28px; background-image: url(http://gravatar.com/avatar/934de9c1bb70346d4141722fb35c78b6?size=28&amp;d=http%3A%2F%2Flocalhost%3A3020%2Fimages%2Fdefaultavatar%2Fdefault.avatar.65.png);"></a>
              <span class="friend-name">Emre Durmuş</span>
              <i></i>
            </div>
          </div>
        """