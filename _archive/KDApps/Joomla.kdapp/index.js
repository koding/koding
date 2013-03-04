(function() {

/* KDAPP STARTS */

/* BLOCK STARTS */

var appStorage, checkPath, fc, installWordpress, kc, nickname, parseOutput, prepareDb, tc;

kc = KD.getSingleton("kiteController");

fc = KD.getSingleton("finderController");

tc = fc.treeController;

nickname = KD.whoami().profile.nickname;

appStorage = new AppStorage("wp-installer", "1.0");

parseOutput = function(res, err) {
  var output;
  if (err == null) err = false;
  if (err) res = "<br><cite style='color:red'>[ERROR] " + res + "</cite><br>";
  output = split.output;
  output.setPartial(res);
  return output.utils.wait(100, function() {
    return output.scrollTo({
      top: output.getScrollHeight(),
      duration: 100
    });
  });
};

prepareDb = function(callback) {
  var dbName, dbPass, dbUser,
    _this = this;
  dbUser = dbName = __utils.generatePassword(15 - nickname.length, true);
  dbPass = __utils.generatePassword(40, false);
  parseOutput("<br>creating a database....<br>");
  return kc.run({
    kiteName: "databases",
    toDo: "createMysqlDatabase",
    withArgs: {
      dbName: dbName,
      dbUser: dbUser,
      dbPass: dbPass
    }
  }, function(err, response) {
    if (err) {
      parseOutput(err.message, true);
      return typeof callback === "function" ? callback(err) : void 0;
    } else {
      parseOutput("<br>database created:<br>\nDatabase User: " + response.dbUser + "<br>\nDatabase Name: " + response.dbName + "<br>\nDatabase Host: " + response.dbHost + "<br>\nDatabase Pass: " + response.dbPass + "<br>\n<br>");
      return callback(null, response);
    }
  });
};

checkPath = function(formData, callback) {
  var domain, path,
    _this = this;
  path = formData.path, domain = formData.domain;
  return kc.run({
    withArgs: {
      command: "stat /Users/" + nickname + "/Sites/" + domain + "/website/" + path
    }
  }, function(err, response) {
    if (response) {
      parseOutput("Specified path isn't available, please delete it or select another path!", true);
    }
    return typeof callback === "function" ? callback(err, response) : void 0;
  });
};

installWordpress = function(formData, callback) {
  var commands, domain, path, timestamp;
  path = formData.path, domain = formData.domain, timestamp = formData.timestamp;
  commands = {
    a: "mkdir -vp '/Users/" + nickname + "/Sites/" + domain + "/website/app." + timestamp + "'",
    b: "curl --location 'http://wordpress.org/latest.zip' >'/Users/" + nickname + "/Sites/" + domain + "/website/app." + timestamp + ".zip'",
    c: "unzip '/Users/" + nickname + "/Sites/" + domain + "/website/app." + timestamp + ".zip' -d '/Users/" + nickname + "/Sites/" + domain + "/website/app." + timestamp + "'",
    d: "chmod 774 -R '/Users/" + nickname + "/Sites/" + domain + "/website/app." + timestamp + "'",
    e: "rm '/Users/" + nickname + "/Sites/" + domain + "/website/app." + timestamp + ".zip'",
    f: "mv '/Users/" + nickname + "/Sites/" + domain + "/website/app." + timestamp + "/wordpress' '/Users/" + nickname + "/Sites/" + domain + "/website/" + path + "'",
    g: "rm -r '/Users/" + nickname + "/Sites/" + domain + "/website/app." + timestamp + "'"
  };
  if (path === "") {
    commands.f = "cp -R /Users/" + nickname + "/Sites/" + domain + "/website/app." + timestamp + "/wordpress/* /Users/" + nickname + "/Sites/" + domain + "/website";
  }
  parseOutput(commands.a);
  return kc.run({
    withArgs: {
      command: commands.a
    }
  }, function(err, res) {
    if (err) {
      return parseOutput(err, true);
    } else {
      parseOutput(res);
      parseOutput("<br>$> " + commands.b + "<br>");
      return kc.run({
        withArgs: {
          command: commands.b
        }
      }, function(err, res) {
        if (err) {
          return parseOutput(err, true);
        } else {
          parseOutput(res);
          parseOutput("<br>$> " + commands.c + "<br>");
          return kc.run({
            withArgs: {
              command: commands.c
            }
          }, function(err, res) {
            if (err) {
              return parseOutput(err, true);
            } else {
              parseOutput(res);
              parseOutput("<br>$> " + commands.d + "<br>");
              return kc.run({
                withArgs: {
                  command: commands.d
                }
              }, function(err, res) {
                if (err) {
                  return parseOutput(err, true);
                } else {
                  parseOutput(res);
                  parseOutput("<br>$> " + commands.e + "<br>");
                  return kc.run({
                    withArgs: {
                      command: commands.e
                    }
                  }, function(err, res) {
                    if (err) {
                      return parseOutput(err, true);
                    } else {
                      parseOutput(res);
                      parseOutput("<br>$> " + commands.f + "<br>");
                      return kc.run({
                        withArgs: {
                          command: commands.f
                        }
                      }, function(err, res) {
                        if (err) {
                          return parseOutput(err, true);
                        } else {
                          parseOutput(res);
                          parseOutput("<br>#############");
                          parseOutput("<br>Wordpress successfully installed to: /Users/" + nickname + "/Sites/" + domain + "/website/" + path);
                          parseOutput("<br>#############<br>");
                          if (typeof callback === "function") callback(formData);
                          appStorage.fetchStorage(function() {
                            var blogs;
                            blogs = appStorage.getValue("blogs") || [];
                            blogs.push(formData);
                            return appStorage.setValue("blogs", blogs, noop);
                          });
                          parseOutput("<br>$> " + commands.g + "<br>");
                          return kc.run({
                            withArgs: {
                              command: commands.g
                            }
                          }, function(err, res) {
                            if (err) {
                              return parseOutput(err, true);
                            } else {
                              parseOutput(res);
                              return parseOutput("<br>temp files cleared!");
                            }
                          });
                        }
                      });
                    }
                  });
                }
              });
            }
          });
        }
      });
    }
  });
};


/* BLOCK ENDS */



/* BLOCK STARTS */

var Pane, WpApp, WpSplit,
  __hasProp = Object.prototype.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; };

WpApp = (function(_super) {

  __extends(WpApp, _super);

  function WpApp() {
    var _this = this;
    WpApp.__super__.constructor.apply(this, arguments);
    this.listenWindowResize();
    this.dashboardTabs = new KDTabView({
      hideHandleCloseIcons: true,
      hideHandleContainer: true,
      cssClass: "wp-installer-tabs"
    });
    this.consoleToggle = new KDToggleButton({
      states: [
        "Console", function(callback) {
          this.setClass("toggle");
          split.resizePanel(250, 0);
          return callback(null);
        }, "Console &times;", function(callback) {
          this.unsetClass("toggle");
          split.resizePanel(0, 1);
          return callback(null);
        }
      ]
    });
    this.buttonGroup = new KDButtonGroupView({
      buttons: {
        "Dashboard": {
          cssClass: "clean-gray toggle",
          callback: function() {
            return _this.dashboardTabs.showPaneByIndex(0);
          }
        },
        "Install a new Wordpress": {
          cssClass: "clean-gray",
          callback: function() {
            return _this.dashboardTabs.showPaneByIndex(1);
          }
        }
      }
    });
    this.dashboardTabs.on("PaneDidShow", function(pane) {
      if (pane.name === "dashboard") {
        return _this.buttonGroup.buttonReceivedClick(_this.buttonGroup.buttons.Dashboard);
      } else {
        return _this.buttonGroup.buttonReceivedClick(_this.buttonGroup.buttons["Install a new Wordpress"]);
      }
    });
  }

  WpApp.prototype.viewAppended = function() {
    var dashboard, installPane;
    WpApp.__super__.viewAppended.apply(this, arguments);
    this.dashboardTabs.addPane(dashboard = new DashboardPane({
      cssClass: "dashboard",
      name: "dashboard"
    }));
    this.dashboardTabs.addPane(installPane = new InstallPane({
      name: "install"
    }));
    this.dashboardTabs.showPane(dashboard);
    installPane.on("WordPressInstalled", function(formData) {
      var domain, path;
      domain = formData.domain, path = formData.path;
      dashboard.putNewItem(formData);
      return __utils.wait(200, function() {
        return tc.refreshFolder(tc.nodes["/Users/" + nickname + "/Sites/" + domain + "/website"], function() {
          return __utils.wait(200, function() {
            return tc.selectNode(tc.nodes["/Users/" + nickname + "/Sites/" + domain + "/website/" + path]);
          });
        });
      });
    });
    return this._windowDidResize();
  };

  WpApp.prototype._windowDidResize = function() {
    return this.dashboardTabs.setHeight(this.getHeight() - this.$('>header').height());
  };

  WpApp.prototype.pistachio = function() {
    return "<header>\n  <figure></figure>\n  <article>\n    <h3>Wordpress Installer</h3>\n    <p>This application installs wordpress instances and gives you a dashboard of what is already installed</p>\n  </article>\n  <section>\n  {{> @buttonGroup}}\n  {{> @consoleToggle}}\n  </section>\n</header>\n{{> @dashboardTabs}}";
  };

  return WpApp;

})(JView);

WpSplit = (function(_super) {

  __extends(WpSplit, _super);

  function WpSplit(options, data) {
    this.output = new KDScrollView({
      tagName: "pre",
      cssClass: "terminal-screen"
    });
    this.wpApp = new WpApp;
    options.views = [this.wpApp, this.output];
    WpSplit.__super__.constructor.call(this, options, data);
  }

  WpSplit.prototype.viewAppended = function() {
    WpSplit.__super__.viewAppended.apply(this, arguments);
    return this.panels[1].setClass("terminal-tab");
  };

  return WpSplit;

})(KDSplitView);

Pane = (function(_super) {

  __extends(Pane, _super);

  function Pane() {
    Pane.__super__.constructor.apply(this, arguments);
  }

  Pane.prototype.viewAppended = function() {
    this.setTemplate(this.pistachio());
    return this.template.update();
  };

  return Pane;

})(KDTabPaneView);


/* BLOCK ENDS */



/* BLOCK STARTS */

var DashboardPane, InstalledAppListItem,
  __hasProp = Object.prototype.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; };

DashboardPane = (function(_super) {

  __extends(DashboardPane, _super);

  function DashboardPane() {
    var _this = this;
    DashboardPane.__super__.constructor.apply(this, arguments);
    this.listController = new KDListViewController({
      lastToFirst: true,
      viewOptions: {
        type: "wp-blog",
        itemClass: InstalledAppListItem
      }
    });
    this.listWrapper = this.listController.getView();
    this.notice = new KDCustomHTMLView({
      tagName: "p",
      cssClass: "why-u-no",
      partial: "Why u no create wordpress!!!"
    });
    this.notice.hide();
    this.listController.getListView().on("DeleteLinkClicked", function(listItemView) {
      var command, domain, name, path, _ref;
      _this.removeItem(listItemView);
      _ref = listItemView.getData(), path = _ref.path, domain = _ref.domain, name = _ref.name;
      command = "rm -r '/Users/" + nickname + "/Sites/" + domain + "/website/" + path + "'";
      parseOutput("<br><br>Deleting /Users/" + nickname + "/Sites/" + domain + "/website/" + path + "<br><br>");
      parseOutput(command);
      return kc.run({
        withArgs: {
          command: command
        }
      }, function(err, res) {
        if (err) {
          parseOutput(err, true);
          new KDNotificationView({
            title: "There was an error, you may need to remove it manually!",
            duration: 3333
          });
        } else {
          parseOutput("<br><br>#############");
          parseOutput("<br>" + name + " successfully deleted.");
          parseOutput("<br>#############<br><br>");
          tc.refreshFolder(tc.nodes["/Users/" + nickname + "/Sites/" + domain + "/website"]);
        }
        return __utils.wait(1500, function() {
          return split.resizePanel(0, 1);
        });
      });
    });
  }

  DashboardPane.prototype.removeItem = function(listItemView) {
    var _this = this;
    this.listController.removeItem(listItemView);
    return appStorage.fetchStorage(function(storage) {
      var blogs;
      blogs = appStorage.getValue("blogs") || [];
      if (blogs.length === 0) return _this.notice.show();
    });
  };

  DashboardPane.prototype.putNewItem = function(formData, resizeSplit) {
    var tabs;
    if (resizeSplit == null) resizeSplit = true;
    tabs = this.getDelegate();
    tabs.showPane(this);
    this.listController.addItem(formData);
    this.notice.hide();
    if (resizeSplit) {
      return __utils.wait(1500, function() {
        return split.resizePanel(0, 1);
      });
    }
  };

  DashboardPane.prototype.viewAppended = function() {
    var _this = this;
    DashboardPane.__super__.viewAppended.apply(this, arguments);
    return appStorage.fetchStorage(function(storage) {
      var blogs;
      blogs = appStorage.getValue("blogs") || [];
      if (blogs.length > 0) {
        blogs.sort(function(a, b) {
          if (a.timestamp < b.timestamp) {
            return -1;
          } else {
            return 1;
          }
        });
        return blogs.forEach(function(item) {
          return _this.putNewItem(item, false);
        });
      } else {
        return _this.notice.show();
      }
    });
  };

  DashboardPane.prototype.pistachio = function() {
    return "{{> @notice}}\n{{> @listWrapper}}";
  };

  return DashboardPane;

})(Pane);

InstalledAppListItem = (function(_super) {

  __extends(InstalledAppListItem, _super);

  function InstalledAppListItem(options, data) {
    var _this = this;
    options.type = "wp-blog";
    InstalledAppListItem.__super__.constructor.call(this, options, data);
    this["delete"] = new KDCustomHTMLView({
      tagName: "a",
      cssClass: "delete-link",
      click: function(pubInst, event) {
        var blogs;
        split.resizePanel(250, 0);
        blogs = appStorage.getValue("blogs");
        blogs.splice(blogs.indexOf(_this.getData()), 1);
        return appStorage.setValue("blogs", blogs, function() {
          return _this.getDelegate().emit("DeleteLinkClicked", _this);
        });
      }
    });
  }

  InstalledAppListItem.prototype.viewAppended = function() {
    var _this = this;
    this.setTemplate(this.pistachio());
    this.template.update();
    return this.utils.wait(function() {
      return _this.setClass("in");
    });
  };

  InstalledAppListItem.prototype.pistachio = function() {
    var domain, name, path, timestamp, url, _ref;
    _ref = this.getData(), path = _ref.path, timestamp = _ref.timestamp, domain = _ref.domain, name = _ref.name;
    url = "http://" + domain + "/" + path;
    return "{{> @delete}}\n<a target='_blank' class='name-link' href='" + url + "'>{{ #(name)}}</a>\n<a target='_blank' class='admin-link' href='" + url + (path === "" ? '' : '/') + "wp-admin'>Admin</a>\n<a target='_blank' class='raw-link' href='" + url + "'>" + url + "</a>\n<time datetime='" + (new Date(timestamp)) + "'>" + ($.timeago(new Date(timestamp))) + "</time>";
  };

  return InstalledAppListItem;

})(KDListItemView);


/* BLOCK ENDS */



/* BLOCK STARTS */

var InstallPane,
  __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  __hasProp = Object.prototype.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; };

InstallPane = (function(_super) {

  __extends(InstallPane, _super);

  function InstallPane() {
    this.submit = __bind(this.submit, this);
    var domainsPath,
      _this = this;
    InstallPane.__super__.constructor.apply(this, arguments);
    this.form = new KDFormViewWithFields({
      callback: this.submit.bind(this),
      buttons: {
        install: {
          title: "Install Wordpress",
          style: "cupid-green",
          type: "submit",
          loader: {
            color: "#444444",
            diameter: 12
          }
        }
      },
      fields: {
        name: {
          label: "Name of your blog:",
          name: "name",
          placeholder: "type a name for your blog...",
          defaultValue: "My Wordpress",
          validate: {
            rules: {
              required: "yes"
            },
            messages: {
              required: "a name for your wordpress is required!"
            }
          },
          keyup: function() {
            return _this.completeInputs();
          },
          blur: function() {
            return _this.completeInputs();
          }
        },
        domain: {
          label: "Domain :",
          name: "domain",
          itemClass: KDSelectBox,
          defaultValue: "" + nickname + ".koding.com",
          nextElement: {
            pathExtension: {
              label: "/my-wordpress/",
              type: "hidden"
            }
          }
        },
        path: {
          label: "Path :",
          name: "path",
          placeholder: "type a path for your blog...",
          hint: "leave empty if you want your blog to work on your domain root",
          defaultValue: "my-wordpress",
          keyup: function() {
            return _this.completeInputs(true);
          },
          blur: function() {
            return _this.completeInputs(true);
          },
          validate: {
            rules: {
              regExp: /(^$)|(^[a-z\d]+([-][a-z\d]+)*$)/i
            },
            messages: {
              regExp: "please enter a valid path!"
            }
          },
          nextElement: {
            timestamp: {
              name: "timestamp",
              type: "hidden",
              defaultValue: Date.now()
            }
          }
        }
      }
    });
    this.form.on("FormValidationFailed", function() {
      return _this.form.buttons["Install Wordpress"].hideLoader();
    });
    domainsPath = "/Users/" + nickname + "/Sites";
    kc.run({
      withArgs: {
        command: "ls " + domainsPath + " -lpva"
      }
    }, function(err, response) {
      var domain, files, newSelectOptions;
      if (err) {
        return warn(err);
      } else {
        files = FSHelper.parseLsOutput([domainsPath], response);
        newSelectOptions = [];
        files.forEach(function(domain) {
          return newSelectOptions.push({
            title: domain.name,
            value: domain.name
          });
        });
        domain = _this.form.inputs.domain;
        return domain.setSelectOptions(newSelectOptions);
      }
    });
  }

  InstallPane.prototype.completeInputs = function(fromPath) {
    var name, path, pathExtension, slug, val, _ref;
    if (fromPath == null) fromPath = false;
    _ref = this.form.inputs, path = _ref.path, name = _ref.name, pathExtension = _ref.pathExtension;
    if (fromPath) {
      val = path.getValue();
      slug = __utils.slugify(val);
      if (/\//.test(val)) path.setValue(val.replace('/', ''));
    } else {
      slug = __utils.slugify(name.getValue());
      path.setValue(slug);
    }
    if (slug) slug += "/";
    return pathExtension.inputLabel.updateTitle("/" + slug);
  };

  InstallPane.prototype.submit = function(formData) {
    var db, domain, failCb, name, path, successCb,
      _this = this;
    split.resizePanel(250, 0);
    path = formData.path, domain = formData.domain, name = formData.name, db = formData.db;
    formData.timestamp = parseInt(formData.timestamp, 10);
    formData.fullPath = "" + domain + "/website/" + path;
    failCb = function() {
      _this.form.buttons["Install Wordpress"].hideLoader();
      return _this.utils.wait(5000, function() {
        return split.resizePanel(0, 1);
      });
    };
    successCb = function() {
      return installWordpress(formData, function(path, timestamp) {
        _this.emit("WordPressInstalled", formData);
        return _this.form.buttons["Install Wordpress"].hideLoader();
      });
    };
    return checkPath(formData, function(err, response) {
      if (err) {
        if (db) {
          return prepareDb(function(err, db) {
            if (err) {
              return failCb();
            } else {
              return successCb();
            }
          });
        } else {
          return successCb();
        }
      } else {
        return failCb();
      }
    });
  };

  InstallPane.prototype.pistachio = function() {
    return "{{> @form}}";
  };

  return InstallPane;

})(Pane);


/* BLOCK ENDS */



/* BLOCK STARTS */

var split;

appView.addSubView(split = new WpSplit({
  type: "horizontal",
  resizable: false,
  sizes: ["100%", null]
}));


/* BLOCK ENDS */

/* KDAPP ENDS */

}).call();