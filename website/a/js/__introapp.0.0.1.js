var EntryPage,IntroPage,IntroView,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child},__indexOf=[].indexOf||function(item){for(var i=0,l=this.length;l>i;i++)if(i in this&&this[i]===item)return i
return-1}
IntroPage=function(_super){function IntroPage(options,data){null==options&&(options={})
IntroPage.__super__.constructor.call(this,options,data)}__extends(IntroPage,_super)
IntroPage.prototype.pistachio=function(){var content,time
content=this.getOption("content")
if(content)return content
time=(new Date).getTime()
return'<div class="slider-page">\n  <div class="slogan">Koding {{#(slogan)}}</div>\n  <div class="wrapper">\n    <figure>\n      <img src="/images/homeslide/'+this.getData().slideImage+"?"+time+'" />\n    </figure>\n    <div class="details">\n      {{#(subSlogan)}}\n    </div>\n  </div>\n</div>'}
return IntroPage}(KDSlidePageView)
EntryPage=function(_super){function EntryPage(){EntryPage.__super__.constructor.call(this,{cssClass:"entryPage"})}__extends(EntryPage,_super)
EntryPage.prototype.viewAppended=function(){var buttons,emailSignupButton,gitHubSignupButton
this.addSubView(new KDCustomHTMLView({cssClass:"top-slogan",partial:"A new way for developers to work\n<div>Software development has finally evolved,<br> It's now social, in the browser and free!</div>"}))
buttons=new KDCustomHTMLView({cssClass:"buttons"})
buttons.addSubView(emailSignupButton=new KDButtonView({cssClass:"email",partial:"<i></i>Sign up <span>with email</span>",callback:function(){return KD.getSingleton("router").handleRoute("/Register")}}))
buttons.addSubView(gitHubSignupButton=new KDButtonView({cssClass:"github",partial:"<i></i>Sign up <span>with GitHub</span>",callback:function(){return KD.getSingleton("oauthController").openPopup("github")}}))
return this.addSubView(buttons)}
return EntryPage}(KDSlidePageView)
IntroView=function(_super){function IntroView(options,data){null==options&&(options={})
options.cssClass="intro-view"
options.bind="scroll mousewheel wheel"
IntroView.__super__.constructor.call(this,options,data)
this.bindTransitionEnd()}__extends(IntroView,_super)
IntroView.prototype.setCurrentPage=function(direction){var _this=this
if(!this._lock){this._lock=!0
this.slider[direction]()
return this.utils.wait(1200,function(){return delete _this._lock})}}
IntroView.prototype.mouseWheel=function(e){var deltaX,deltaY,oevent
oevent=e.originalEvent
if(null!=oevent&&!this._lock){deltaY=oevent.wheelDeltaY||-oevent.deltaY
deltaX=oevent.wheelDeltaX||-oevent.deltaX;-15>deltaY&&this.setCurrentPage("nextPage")
deltaY>15&&this.setCurrentPage("previousPage")
deltaX>15&&this.setCurrentPage("previousSubPage");-15>deltaX&&this.setCurrentPage("nextSubPage")}return KD.utils.stopDOMEvent(e)}
IntroView.prototype.destroyIntro=function(){var _this=this
this.setClass("out")
return this.utils.wait("500",function(){return _this.destroy()})}
IntroView.prototype.viewAppended=function(){var hash,labels,multipleChoice,target,_this=this
this.addSubView(this.slider=new KDSlideShowView({direction:"topToBottom"}))
this.slider.addPage(new EntryPage)
this.slider.addPage(new IntroPage({},{slideImage:"you.svg",slogan:"for <span>You</span>",subSlogan:"<p>\n  You have great ideas.  You want to meet brilliant minds, and bring those ideas to life.  You want to start simple.  Maybe soon you'll have a 10 person team, commanding 100s of servers.\n</p>\n<p>\n  You want to learn Python, Java, C, Go, Nodejs, HTML, CSS or Javascript or any other. Community will help you along the way.\n</p>"}))
this.slider.addPage(new IntroPage({},{slideImage:"developers.svg",slogan:"for <span>Developers</span>",subSlogan:"<p>\n  You will have an amazing virtual machine that is better than your laptop.  It's connected to the internet 100s of times faster.  You can share it with anyone you wish. Clone git repos.  Test and iterate on your code without breaking your setup.\n</p>\n<p>\n  It's free. Koding is your new localhost, in the cloud.\n</p>"}))
this.slider.addPage(new IntroPage({},{slideImage:"education.svg",slogan:"for <span>Education</span>",subSlogan:"<p>\n  Create a group where your students enjoy the resources you provide to them. Make it private or invite-only.  Let them share, collaborate and submit their assignments together.  It doesn't matter if you have ten students, or ten thousand.  Scale from just one to hundreds of computers.\n</p>\n<p>\n  Koding is your new classroom.\n</p>"}))
this.slider.addPage(new IntroPage({},{slideImage:"business.svg",slogan:"for <span>Business</span>",subSlogan:"<p>\n  When you hire someone, they can get up to speed in your development environment in 5 minutes—easily collaborating with others and contributing code.  All without sharing ssh keys or passwords.  Stop cc'ing your team; stop searching through old emails.\n</p>\n<p>\n  Koding is your new workspace.\n</p>"}))
this.slider.addPage(new IntroPage({},{slideImage:"price.svg",slogan:"Pricing",subSlogan:"<p>\n  You'll be able to buy more resources for your personal account or for accounts in your organization.\n</p>\n<p>\n  Coming soon.\n</p>"}))
labels=["Koding","You","Developers","Education","Business","Pricing"]
hash=location.hash.replace(/^\#/,"")
target=__indexOf.call(labels,hash)>=0?hash:"Koding"
this.addSubView(multipleChoice=new KDMultipleChoice({title:"",labels:labels,defaultValue:[target],multiple:!1,cssClass:"bottom-menu",callback:function(state){_this.slider.jump(labels.indexOf(state))
"Koding"===state&&(state="")
return history.replaceState({},state,"/#"+state)}}))
this.slider.on("CurrentPageChanged",function(current){multipleChoice.setValue(labels[current.x],!1)
if(current.x>0){_this.setClass("ghost")
multipleChoice.setClass("black")
return _this.utils.wait(500,function(){return $("#main-header").addClass("black")})}$("#main-header").removeClass("black")
_this.unsetClass("ghost")
return _this.utils.wait(500,function(){return multipleChoice.unsetClass("black")})})
this.utils.wait(300,function(){return"Koding"!==target?multipleChoice.setValue(target):void 0})
$(window).on("resize orientationchange",function(){return _this.updateSize()})
return this.updateSize()}
IntroView.prototype.updateSize=function(){var sizes
sizes=this.slider.currentPage.getBounds()
return this.slider.setCss({fontSize:Math.max(Math.min((sizes.w+sizes.h)/80,parseFloat(20)),parseFloat(12))})}
return IntroView}(JView)
KD.introView=new IntroView
KD.introView.appendToDomBody()
KD.utils.defer(function(){return KD.introView.setClass("in")})

//@ sourceMappingURL=/js/__introapp.0.0.1.js.map