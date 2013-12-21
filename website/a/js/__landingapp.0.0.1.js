var LandingView,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
LandingView=function(_super){function LandingView(options,data){var disabled,url,_this=this
null==options&&(options={})
options.cssClass=KD.utils.curry("landing-view",options.cssClass)
LandingView.__super__.constructor.call(this,options,data)
this.username=KD.landingOptions.username
if(this.username){disabled=!1
this.login=new KDCustomHTMLView
url=KD.getReferralUrl(this.username)}else{disabled=!0
this.login=new KDCustomHTMLView({tagName:"span",cssClass:"login",partial:"Login",click:function(){return KD.requireMembership()}})}this.inviteGmailContacts=new KDButtonView({style:"invite-button gmail",title:"Invite <strong>Gmail</strong> contacts",icon:!0,callback:this.bound("showReferralModal")})
this.emailAddressInput=new KDInputView({type:"textarea",autogrow:!0,placeholder:"Type one email address per line"})
this.emailAddressSubmit=new KDButtonView({style:"submit-email-addresses",title:"Send",loader:{diameter:24},callback:function(){_this.emailAddressSubmit.hideLoader()
return""!==_this.emailAddressInput.getValue()?_this.requireLogin(_this.bound("submitEmailAddresses")):void 0}})
this.invitationSentButton=new KDButtonView({style:"invitations-sent hidden",title:"Sent!"})
this.errorMessage=new KDCustomHTMLView({cssClass:"error-message hidden"})
this.shareLinks=new KDCustomHTMLView({tagName:"span",cssClass:"share-links"})
this.referrerUrlInput=new KDInputView({cssClass:"referrer-url",attributes:{readonly:"true"},defaultValue:url?url:void 0,placeholder:"Login to see your referrer URL",click:function(){return this.selectAll()}})
this.shareLinks.addSubView(this.twitter=new TwitterShareLink({url:url,disabled:disabled}))
this.shareLinks.addSubView(this.facebook=new FacebookShareLink({url:url,disabled:disabled}))
this.shareLinks.addSubView(this.linkedin=new LinkedInShareLink({url:url,disabled:disabled}))
KD.getSingleton("mainController").on("AccountChanged",this.bound("enable"))}__extends(LandingView,_super)
LandingView.prototype.requireLogin=function(fn){if(KD.isLoggedIn())return fn()
KD.getSingleton("mainController").once("AccountChanged",fn)
return KD.requireMembership()}
LandingView.prototype.showReferralModal=function(){var cb
cb=function(){var modal
modal=new ReferrerModal({overlay:!1,onlyInviteTab:!0})
return modal.checkGoogleLinkStatus()}
return function(){return this.requireLogin(cb)}}()
LandingView.prototype.submitEmailAddresses=function(){var emails,fails,_this=this
emails=this.emailAddressInput.getValue().split("\n")
emails=emails.filter(function(email){return email.length>0})
if(emails.length){fails=[]
this.emailAddressSubmit.showLoader()
return async.map(emails,function(email,callback){return KD.remote.api.JReferrableEmail.invite(email,function(err){err&&fails.push(email)
return callback()})},function(){_this.errorMessage.hide()
_this.emailAddressSubmit.hideLoader()
if(fails.length)return _this.decorateEmailAddressError(fails)
_this.emailAddressSubmit.hide()
return _this.invitationSentButton.show()})}this.emailAddressSubmit.hideLoader()}
LandingView.prototype.enable=function(){return KD.isLoggedIn()?this.login.hide():void 0}
LandingView.prototype.pistachio=function(){return""}
return LandingView}(JView)

var SpaceshipLandingPage,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
SpaceshipLandingPage=function(_super){function SpaceshipLandingPage(options,data){null==options&&(options={})
options.cssClass="spaceship"
SpaceshipLandingPage.__super__.constructor.call(this,options,data)
this.share=new KDCustomHTMLView({cssClass:"share"})
this.share.addSubView(new KDCustomHTMLView({tagName:"h3",partial:"Other ways to <strong>share:</strong>"}))
this.share.addSubView(this.referrerUrlInput)
this.share.addSubView(this.shareLinks)}__extends(SpaceshipLandingPage,_super)
SpaceshipLandingPage.prototype.enable=function(){var shareLink,url,_i,_len,_ref,_results
SpaceshipLandingPage.__super__.enable.apply(this,arguments)
if(KD.isLoggedIn()){url=KD.getReferralUrl(KD.nick())
this.referrerUrlInput.setValue(url)
this.referrerUrlInput.makeEnabled()
_ref=[this.twitter,this.facebook,this.linkedin]
_results=[]
for(_i=0,_len=_ref.length;_len>_i;_i++){shareLink=_ref[_i]
shareLink.setOption("url",url)
_results.push(shareLink.enable())}return _results}}
SpaceshipLandingPage.prototype.decorateEmailAddressError=function(emails){var email,lines,_i,_len
this.emailAddressInput.setClass("error")
lines='<ul class="email-list">Errors occurred with following email addresses:'
for(_i=0,_len=emails.length;_len>_i;_i++){email=emails[_i]
lines+="<li>"+email+"</li>"}lines+="</ul>"
this.errorMessage.updatePartial(lines)
return this.errorMessage.show()}
SpaceshipLandingPage.prototype.pistachio=function(){return'<div class="top">\n  <img class="logo" src="/images/landing/logo.png" />\n  {{> this.login}}\n  <header class="title">Share the <strong>power</strong> of Koding!</header>\n</div>\n<div class="middle">\n  <div class="left">\n    <img src="/images/landing/spaceship.png" />\n  </div>\n  <div class="right">\n    <h2>Get up to <strong>16</strong> GB</h2>\n    <p>We’ll give you <strong>250 MB free disk space</strong> for every friend that joins Koding (up to a limit of 16 GB)</p>\n    {{> this.inviteGmailContacts}}\n    <div class="invite-by-email">\n      {{> this.emailAddressInput}}\n      {{> this.emailAddressSubmit}}\n      {{> this.invitationSentButton}}\n      {{> this.errorMessage}}\n    </div>\n    <hr />\n    {{> this.share}}\n  </div>\n</div>'}
return SpaceshipLandingPage}(LandingView)

var LandingAppView,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
LandingAppView=function(_super){function LandingAppView(options,data){null==options&&(options={})
options.cssClass="landingapp-view"
options.pageClass||(options.pageClass=LandingView)
LandingAppView.__super__.constructor.call(this,options,data)}__extends(LandingAppView,_super)
LandingAppView.prototype.viewAppended=function(){var pageClass,pageContainer
this.addSubView(pageContainer=new KDView({cssClass:"page-container"}))
pageClass=this.getOptions().pageClass
return pageClass?pageContainer.addSubView(new pageClass):void 0}
LandingAppView.classMap={spaceship:SpaceshipLandingPage}
return LandingAppView}(KDView)
!function(){var landingAppView
landingAppView=new LandingAppView({pageClass:LandingAppView.classMap[KD.landingOptions.page]})
return landingAppView.appendToDomBody()}()

//@ sourceMappingURL=/js/__landingapp.0.0.1.js.map