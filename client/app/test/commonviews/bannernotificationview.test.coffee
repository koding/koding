kd                     = require 'kd'
expect                 = require 'expect'
BannerNotificationView = require '../../lib/commonviews/bannernotificationview'

describe 'Banner notification', ->

  it 'should produce correct pistachio with content without strip data', ->
    options =
      title   : 'BannerTitle'
      content : 'BannerContent'
    banner = new BannerNotificationView options

    expect(banner.domElement[0].innerHTML).toEqual('<p title="BannerTitle \
     BannerContent"><b>BannerTitle</b> <span>BannerContent</span></p>\
     <a class="close" href="#"></a>')

  it 'should produce correct pistachio', ->
    options =
      title   : 'BannerTitle'
      content : 'Banner Content <p> banner content </p>'
    banner = new BannerNotificationView options

    expect(banner.domElement[0].innerHTML).toEqual('<p title="BannerTitle \
      Banner Content  banner content "><b>BannerTitle</b> <span>Banner Content <p> \
      banner content </p></span></p><a class="close" href="#"></a>')
