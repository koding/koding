(function(){var AppController, KDView, KDViewController, PreviewerButton, PreviewerView, ViewerTopBar, framework;
var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; }, __hasProp = Object.prototype.hasOwnProperty, __extends = function(child, parent) {
  for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; }
  function ctor() { this.constructor = child; }
  ctor.prototype = parent.prototype;
  child.prototype = new ctor;
  child.__super__ = parent.prototype;
  return child;
}, __slice = Array.prototype.slice;
framework = requirejs('Framework');
KDView = framework.KDView, KDViewController = framework.KDViewController;
AppController = (function() {
  __extends(AppController, KDViewController);
  function AppController() {
    this.openFile = __bind(this.openFile, this);
    this.bringToFront = __bind(this.bringToFront, this);
    this.initAndBringToFront = __bind(this.initAndBringToFront, this);
    this.initApplication = __bind(this.initApplication, this);
    AppController.__super__.constructor.apply(this, arguments);
  }
  AppController.prototype.initApplication = function(options, callback) {
    this.openDocuments = [];
    return this.applyStyleSheet(__bind(function() {
      this.propagateEvent({
        KDEventType: 'ApplicationInitialized',
        globalEvent: true
      });
      return callback();
    }, this));
  };
  AppController.prototype.initAndBringToFront = function(options, callback) {
    return this.initApplication(options, __bind(function() {
      return this.bringToFront(null, callback);
    }, this));
  };
  AppController.prototype.bringToFront = function(frontDocument, path, callback) {
    if (!frontDocument) {
      if (this.doesOpenDocumentsExist()) {
        frontDocument = this.getFrontDocument();
      } else {
        frontDocument = this.createNewDocument();
      }
    }
    this.propagateEvent({
      KDEventType: 'ApplicationWantsToBeShown',
      globalEvent: true
    }, {
      options: {
        hiddenHandle: false,
        type: 'application',
        name: path,
        applicationType: 'Viewer.kdApplication'
      },
      data: frontDocument
    });
    return callback();
  };
  AppController.prototype.openFile = function(path, options) {
    var document, _ref;
    if (options == null) {
      options = {};
    }
    if (!((_ref = (document = this.getFrontDocument())) != null ? _ref.isDocumentClean() : void 0)) {
      document = this.createNewDocument();
    }
    return this.bringToFront(document, path, function() {
      return document.openPath(path);
    });
  };
  AppController.prototype.doesOpenDocumentsExist = function() {
    if (this.openDocuments.length > 0) {
      return true;
    } else {
      return false;
    }
  };
  AppController.prototype.getOpenDocuments = function() {
    return this.openDocuments;
  };
  AppController.prototype.getFrontDocument = function() {
    var backDocuments, frontDocument, _i, _ref;
    _ref = this.getOpenDocuments(), backDocuments = 2 <= _ref.length ? __slice.call(_ref, 0, _i = _ref.length - 1) : (_i = 0, []), frontDocument = _ref[_i++];
    return frontDocument;
  };
  AppController.prototype.addOpenDocument = function(document) {
    appManager.addOpenTab(document, 'Viewer.kdApplication');
    return this.openDocuments.push(document);
  };
  AppController.prototype.removeOpenDocument = function(document) {
    appManager.removeOpenTab(document, this);
    return this.openDocuments.splice(this.openDocuments.indexOf(document), 1);
  };
  AppController.prototype.createNewDocument = function() {
    var document;
    document = new PreviewerView();
    document.registerListener({
      KDEventTypes: "viewAppended",
      callback: this.loadDocumentView,
      listener: this
    });
    document.registerListener({
      KDEventTypes: 'ViewClosed',
      listener: this,
      callback: this.closeDocument
    });
    this.addOpenDocument(document);
    return document;
  };
  AppController.prototype.closeDocument = function(document) {
    document.parent.removeSubView(document);
    this.removeOpenDocument(document);
    this.propagateEvent({
      KDEventType: 'ApplicationWantsToClose',
      globalEvent: true
    }, {
      data: document
    });
    return document.destroy();
  };
  AppController.prototype.loadDocumentView = function(documentView) {
    var file;
    if ((file = documentView.file) != null) {
      return document.openPath(file.path);
    }
  };
  AppController.prototype.applyStyleSheet = function(callback) {
    return requirejs(['text!KDApplications/Viewer.kdapplication/app.css'], function(css) {
      $("<style type='text/css'>" + css + "</style>").appendTo("head");
      return typeof callback === "function" ? callback() : void 0;
    });
  };
  return AppController;
})();
define(function() {
  var application, bringToFront, initAndBringToFront, initApplication, openFile;
  application = new AppController();
  initApplication = application.initApplication, initAndBringToFront = application.initAndBringToFront, bringToFront = application.bringToFront, openFile = application.openFile;
  ({
    initApplication: initApplication,
    initAndBringToFront: initAndBringToFront,
    bringToFront: bringToFront,
    openFile: openFile
  });
  return application;
});
PreviewerView = (function() {
  __extends(PreviewerView, KDView);
  function PreviewerView(options, data) {
    if (options == null) {
      options = {};
    }
    options.cssClass = 'previewer-body';
    this.clean = true;
    PreviewerView.__super__.constructor.call(this, options, data);
  }
  PreviewerView.prototype.openPath = function(path) {
    this.path = path;
    this.clean = false;
    this.iframe.$().attr('src', path);
    return this.viewerHeader.setPath(path);
  };
  PreviewerView.prototype.refreshIFrame = function() {
    return this.iframe.$().attr('src', this.path);
  };
  PreviewerView.prototype.isDocumentClean = function() {
    return this.clean;
  };
  PreviewerView.prototype.viewAppended = function() {
    this.addSubView(this.viewerHeader = new ViewerTopBar({}, null));
    return this.addSubView(this.iframe = new KDView({
      tagName: 'iframe'
    }));
  };
  return PreviewerView;
})();
ViewerTopBar = (function() {
  __extends(ViewerTopBar, KDView);
  function ViewerTopBar(options, data) {
    var pageLocation, refreshButton;
    options.cssClass = 'viewer-header top-bar clearfix';
    ViewerTopBar.__super__.constructor.call(this, options, data);
    this.pageLocation = pageLocation = new KDView({
      tagName: 'p',
      cssClass: 'viewer-title',
      partial: ''
    });
    this.refreshButton = refreshButton = new PreviewerButton({}, this.getData());
  }
  ViewerTopBar.prototype.viewAppended = function() {
    this.addSubView(this.pageLocation = new KDView({
      tagName: 'p',
      cssClass: 'viewer-title',
      partial: ''
    }));
    return this.addSubView(this.refreshButton = new PreviewerButton({}, null));
  };
  ViewerTopBar.prototype.setPath = function(path) {
    return this.pageLocation.$().text("" + path);
  };
  return ViewerTopBar;
})();
PreviewerButton = (function() {
  __extends(PreviewerButton, KDView);
  function PreviewerButton(options, data) {
    this.click = __bind(this.click, this);    options = $.extend({
      tagName: 'button',
      cssClass: 'clean-gray',
      partial: '<span class="icon refresh-btn"></span>'
    }, options);
    PreviewerButton.__super__.constructor.call(this, options, data);
  }
  PreviewerButton.prototype.click = function() {
    return this.parent.parent.refreshIFrame();
  };
  return PreviewerButton;
})();}).call(this);