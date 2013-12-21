var PricingAppController,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
PricingAppController=function(_super){function PricingAppController(options,data){null==options&&(options={})
options.view=new PricingAppView({params:options.params,workflow:this.createWorkflow(),cssClass:"content-page pricing"})
options.appInfo={title:"Pricing"}
PricingAppController.__super__.constructor.call(this,options,data)}__extends(PricingAppController,_super)
"localhost"===location.hostname&&KD.registerAppClass(PricingAppController,{name:"Pricing",route:"/Pricing"})
PricingAppController.prototype.createWorkflow=function(){var paymentController,workflow,_this=this
paymentController=KD.getSingleton("paymentController")
workflow=paymentController.createUpgradeWorkflow("vm")
workflow.on("Finished",function(){return _this.getView().showThankYou(workflow.getData())})
return workflow.on("Cancel",function(){return _this.getView().showCancellation()})}
return PricingAppController}(KDViewController)

var PricingAppView,_ref,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
PricingAppView=function(_super){function PricingAppView(){_ref=PricingAppView.__super__.constructor.apply(this,arguments)
return _ref}__extends(PricingAppView,_super)
PricingAppView.prototype.viewAppended=function(){return this.addSubView(this.getOptions().workflow)}
PricingAppView.prototype.hideWorkflow=function(){return this.getOptions().workflow.hide()}
PricingAppView.prototype.showThankYou=function(data){this.hideWorkflow()
this.thankYou=new KDCustomHTMLView({partial:"<h1>Thank you!</h1>\n<p>\n  Your order has been processed.\n</p>\n"+(data.createAccount?"<p>Please check your email for your registration link.</p>":"<p>We hope you enjoy your new subscription</p>")})
data.createAccount||this.thankYou.addSubView(this.getContinuationLinks())
return this.addSubView(this.thankYou)}
PricingAppView.prototype.getContinuationLinks=function(){return new KDCustomHTMLView({partial:'<ul>\n  <li><a href="/Activity">Activity</a></li>\n  <li><a href="/Account">Account</a></li>\n  <li><a href="/Account/Subscriptions">Subscriptions</a></li>\n  <li><a href="/Environments">Environments</a></li>\n</ul>'})}
PricingAppView.prototype.showCancellation=function(){this.hideWorkflow()
this.cancellation=new KDView({partial:"<h1>This order has been cancelled.</h1>"})
return this.addSubView(this.cancellation)}
return PricingAppView}(KDView)

//@ sourceMappingURL=/js/__app.pricing.0.0.1.js.map