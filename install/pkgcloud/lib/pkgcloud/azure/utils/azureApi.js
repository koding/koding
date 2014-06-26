/**
 *  (C) Microsoft Open Technologies, Inc.   All rights reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

var HeaderConstants = require('./constants').HeaderConstants;
var async = require('async');
var templates = require('../compute/templates/templates');
var _ = require('underscore');
var errs = require('errs');
var URL = require('url');
var cert = require('../utils/cert');
var pkgcloud = require('../../../../../pkgcloud');

var MANAGEMENT_API_VERSION = exports.MANAGEMENT_API_VERSION = '2012-03-01';
var MANAGEMENT_ENDPOINT = exports.MANAGEMENT_ENDPOINT = 'management.core.windows.net';
var STORAGE_ENDPOINT = exports.STORAGE_ENDPOINT = 'blob.core.windows.net';
var STORAGE_API_VERSION = exports.STORAGE_API_VERSION = HeaderConstants.TARGET_STORAGE_VERSION;
var TABLES_ENDPOINT = exports.TABLES_ENDPOINT = 'table.core.windows.net';
var TABLES_API_VERSION = exports.TABLES_API_VERSION = '2012-02-12';
var MINIMUM_POLL_INTERVAL = exports.MINIMUM_POLL_INTERVAL = 3000;

/**
 * createServer()
 *
 * In order to deploy a vm, Azure requires us to do the following
 * before we can actually try to create the vm.
 * 1. get or create a Hosted Service (we use the same name as the vm)
 * 2. resolve the OSImage url to a container on the user's account
 * 3. upload SSH certificate (if necessary)
 * 4. create the VM
 *
 * Note: creating a VM on Azure will fail if one of the following is true
 * 1. The VM (with the same name) already exists
 * 2. The blob storage (with the same name) for the OSImage already exists
 * 3. The VM disk (with the same name) for the OSImage already exists
 * 4. The storage account is in a different azure location than the vm
 *    (East US, West US...)
 *
 * Note: createServer() must wait for Azure to respond if the createDeployment (vm)
 * request succeeded. createServer() asynchronously polls Azure to get
 * the result. Once the result is received, the callback function will be called
 * with the server information or error. The state of returned server will most likely
 * be PROVISIONING or STOPPED. Use server.setWait() to continue polling the server until
 * its status is RUNNING. This entire process may take several minutes.
 */

var createServer = exports.createServer = function (client, options, callback) {
  var vmOptions = {},
    ssh;

  // async execute the following tasks one by one and bail if there is an error
  async.waterfall([
    function (next) {
      // validate createServer options
      validateCreateOptions(options, client.config, next);
    },
    function (next) {
      getHostedServiceProperties(client, options.name, next);
    },
    function (service, next) {
      // if the HostedService does not exist, create it
      vmOptions.hostedService = service;
      if (vmOptions.hostedService === null) {
        createHostedService(client, options, function (err, service) {
          if (err) {
            next(err);
          } else {
            vmOptions.hostedService = service;
            next(null);
          }
        });
      } else {
        next(null);
      }
    },
    function (next) {
      // get the server's OSImage info
      getOSImage(client, options.image, function (err, res) {
        if (err) {
          next(err);
        } else {
          vmOptions.image = res;
          next(null);
        }
      });
    },
    function (next) {
      ssh = options.ssh;
      if (ssh) {
        vmOptions.sshCertInfo = cert.getAzureCertInfo(ssh.cert);
      }
      next();
    },
    function (next) {
      // add the ssh certificate to the service
      if (vmOptions.sshCertInfo) {
        addCertificate(client, options.name, vmOptions.sshCertInfo.cert, ssh.pemPassword, function (err) {
          next(err);
        });
      } else {
        next(null);
      }
    },
    function (next) {
      // create the VM and wait for response
      createVM(client, options, vmOptions, next);
    },
    function (next) {
      // now get the actual server info
      getServer(client, options.name, next);
    }],
    function (err, result) {
      if (err) {
        callback(err);
      } else {
        // return the server info
        callback(null, result);
      }
    }
  );
};

var createVM = function (client, options, vmOptions, callback) {
  // check OS type of image to determine if we are creating a linux or windows VM
  switch (vmOptions.image.OS.toLowerCase()) {
    case 'linux':
      createLinuxVM(client, options, vmOptions, callback);
      break;
    case 'windows':
      createWindowsVM(client, options, vmOptions, callback);
      break;
    default:
      callback(errs.create({message: 'Unknown Image OS: ' + vmOptions.image.OS}));
      break;
  }
};

var getMediaLinkUrl = function (storageAccount, fileName) {
  return 'http://' + storageAccount + '.' + STORAGE_ENDPOINT + '/vhd/' + fileName;
};

var createEndpoints = function (ports) {
  var endPoints = '',
    template = templates.loadSync('endpoint.xml');

  (ports || []).forEach(function (port) {
    endPoints += templates.compileSync(template, port);
  });
  return endPoints;
};

var createLinuxVM = function (client, options, vmOptions, callback) {
  var path = client.subscriptionId + '/services/hostedservices/' + options.name + '/deployments';
  var mediaLink = getMediaLinkUrl(client.config.storageAccount, options.name + '.vhd');
  var label = new Buffer(options.name).toString('base64');

  var configParams = {
    NAME: options.name,
    LABEL_BASE64: label,
    USERNAME: options.username,
    PASSWORD: options.password,
    SSH_CERTIFICATE_FINGERPRINT: vmOptions.sshCertInfo.fingerprint,
    PORT: options.ssh.port || '22',
    LOCAL_PORT: options.ssh.localPort || '22',
    ROLESIZE: options.flavor,
    ENDPOINTS: createEndpoints(options.ports),
    OS_SOURCE_IMAGE_NAME: vmOptions.image.Name,
    OS_IMAGE_MEDIALINK: mediaLink
  };

  makeTemplateRequest(client, path, 'linuxDeployment.xml', configParams, callback);
};

var createWindowsVM = function (client, options, vmOptions, callback) {
  var path = client.subscriptionId + '/services/hostedservices/' + options.name + '/deployments';
  var mediaLink = getMediaLinkUrl(client.config.storageAccount, options.name + '.vhd');
  var label = new Buffer(options.name).toString('base64');

  var configParams = {
    NAME: options.name,
    COMPUTER_NAME: options.computerName || options.name.slice(0, 15),
    LABEL_BASE64: label,
    PASSWORD: options.password,
    ROLESIZE: options.flavor,
    ENDPOINTS: createEndpoints(options.ports),
    OS_SOURCE_IMAGE_NAME: vmOptions.image.Name,
    OS_IMAGE_MEDIALINK: mediaLink
  };

  makeTemplateRequest(client, path, 'windowsDeployment.xml', configParams, callback);
};

var captureServer = function (client, serverName, targetImageName, callback) {
  // <subscription-id>/services/hostedservices/<service-name>/deployments/<deployment-name>/roleinstances/<role-name>/operations
  var path = client.subscriptionId + '/services/hostedservices/' +
    serverName + '/deployments/' +
    serverName + '/roleInstances/' +
    serverName + '/Operations';

  var configParams = {
    NAME: targetImageName
  };

  makeTemplateRequest(client, path, 'captureRole.xml', configParams, callback);
};

var deleteImage = function (client, image, callback) {
  // https://management.core.windows.net/<subscription-id>/services/images/<image-name>
  var path = client.subscriptionId + '/services/images/' + image.Name;

  var configParams = {
    LABEL: image.LABEL
  };

  makeTemplateRequest(client, path, 'deleteImage.xml', configParams, callback);
};

var validateCreateOptions = function (options, config, callback) {
  if (typeof options === 'function') {
    options  = {};
  }
  options = options || {}; // no args

  // check required options values
  ['flavor', 'image', 'name', 'username', 'password', 'location'].forEach(function (member) {
    if (!options[member]) {
      errs.handle(
        errs.create({ message: 'options.' + member + ' is a required argument.' }),
        callback
      );
    }
  });
  callback();
};

/**
 * getServer
 */
var getServer = exports.getServer = function (client, serverName, callback) {
  getServersFromService(client, serverName, function (err, servers) {
    return !err
      ? callback(err, servers[0] ? servers[0] : null)
      : callback(err);
  });
};

var getServers = exports.getServers = function (client, callback) {
  // async execute the following tasks one by one and bail if there is an error
  async.waterfall([
    function (next) {
      // get the list of Hosted Services
      getHostedServices(client, next);
    },
    function (hostedServices, next) {
      // get the list of Servers from the Hosted Services
      getServersFromServices(client, hostedServices, next);
    }],
    function (err, servers) {
      callback(err, servers);
    }
  );
};

var makeTemplateRequest = function (client, path, templateName, params, callback) {
  var headers = {},
    body;

  // async execute the following tasks one by one and bail if there is an error
  async.waterfall([
    function (next) {
      templates.load(templateName, next);
    },
    function (template, next) {
      // compile template with params
      body = _.template(template, params);
      headers['content-length'] = body.length;
      headers['content-type'] = 'application/xml';
      headers['accept'] = 'application/xml';
      client._request({
        method: 'POST',
        path: path,
        body: body,
        headers: headers
      }, function (err, body, res) {
        if (err) {
          return next(err);
        }
        // poll azure for result of request
        pollRequestStatus(client, res.headers['x-ms-request-id'], MINIMUM_POLL_INTERVAL, next);
      });
    }],
    function (err, result) {
      callback(err);
    }
  );
};

var createHostedService = exports.createHostedService = function (client, options, callback) {
  var path = client.subscriptionId + '/services/hostedservices';
  var params = {
    NAME: options.name,
    LABEL_BASE64: new Buffer(options.name).toString('base64'),
    LOCATION: options.location
  };

  makeTemplateRequest(client, path, 'createHostedService.xml', params, callback);
};

/**
 * rebootServer
 * uses Restart Role
 * POST https://management.core.windows.net/<subscription-id>/services/hostedservices/<service-name>/deployments/<deployment-name>/roleinstances/<role-name>/operations
 * A successful operation returns status code 201 (Created). Need to poll for success?
 */
var rebootServer = exports.rebootServer = function (client, serviceName, callback) {
  var path = client.subscriptionId + '/services/hostedservices/' +
    serviceName + '/deployments/' +
    serviceName + '/roleInstances/' +
    serviceName + '/Operations';

  makeTemplateRequest(client, path, 'restartRole.xml', {}, callback);
};

/**
 * stopServer
 * uses Shutdown Role
 * POST https://management.core.windows.net/<subscription-id>/services/hostedservices/<service-name>/deployments/<deployment-name>/roleinstances/<role-name>/operations
 * A successful operation returns status code 201 (Created). Need to poll for success?
 */
var stopServer = exports.stopServer = function (client, serviceName, callback) {
  var path = client.subscriptionId + '/services/hostedservices/' +
    serviceName + '/deployments/' +
    serviceName + '/roleInstances/' +
    serviceName + '/Operations';

  makeTemplateRequest(client, path, 'shutdownRole.xml', {}, callback);
};

var addCertificate = function (client, serviceName, cert, password, callback) {
  var path = client.subscriptionId + '/services/hostedservices/' +
    serviceName + '/certificates';

  var params = {
    CERT_BASE64: new Buffer(cert, 'utf8').toString('base64'),
    PASSWORD: password
  };

  makeTemplateRequest(client, path, 'addCertificate.xml', params, callback);
};

var deleteHostedService = exports.deleteHostedService = function (client, serviceName, callback) {
  // DELETE https://management.core.windows.net/<subscription-id>/services/hostedservices/<service-name>
  var path = client.subscriptionId + '/services/hostedservices/' + serviceName;

  client._request({
    method: 'DELETE',
    path: path
  }, function (err, body, res) {
    if (err) {
      return callback(err);
    }
    // poll azure for result of request
    pollRequestStatus(client, res.headers['x-ms-request-id'], MINIMUM_POLL_INTERVAL, callback);
  });
};

var getHostedServices = exports.getHostedServices = function (client, callback) {
  var path = client.subscriptionId + '/services/hostedservices',
    services = [];

  client.get(path, function (err, body, res) {
    if (err) {
      return callback(err);
    }
    if (body.HostedService) {
      // need to check if azure returned an array or single object
      if (Array.isArray(body.HostedService)) {
        body.HostedService.forEach(function (service) {
          services.push(service);
        });
      } else {
        services.push(body.HostedService);
      }
    }

    callback(null, services);
  });
};

/**
 * destroyServer
 * uses Delete Deployment
 * DELETE https://management.core.windows.net/<subscription-id>/services/hostedservices/<service-name>/deployments/<deployment-name>
 *   Because Delete Deployment is an asynchronous operation, it always returns status code 202 (Accept).
 *   To determine the status code for the operation once it is complete, call Get Operation Status.
 * Because Delete Deployment is an asynchronous operation, it always returns status code 202 (Accept).
 */
var destroyServer = exports.destroyServer = function (client, serverName, callback) {
  var server = null;

  // async execute the following tasks one by one and bail if there is an error
  async.waterfall([
    function (next) {
      // get the list of Hosted Services
      getServer(client, serverName, next);
    },
    function (result, next) {
      server = result;
      // get the list of Hosted Services
      stopServer(client, serverName, next);
    },
    function (next) {
      deleteServer(client, serverName, next);
    },
    function (next) {
      deleteOSDisk(client, server, next);
    },
    function (next) {
      deleteOSBlob(client, server, next);
    },
    function (next) {
      deleteHostedService(client, serverName, next);
    }],
    function (err, result) {
      callback(err, true);
    }
  );
};

var deleteServer = function (client, serverName, callback) {
  var path = client.subscriptionId + '/services/hostedservices/' + serverName;
  path +=  '/deployments/' + serverName;

  client._request({
    method: 'DELETE',
    path: path
  }, function (err, body, res) {
    if (err) {
      return callback(err);
    }
    // poll azure for result of request
    pollRequestStatus(client, res.headers['x-ms-request-id'], MINIMUM_POLL_INTERVAL, callback);
  });
};

var getOSImage = exports.getOSImage = function (client, imageName, callback) {
  var path = '/' + client.subscriptionId + '/services/images/' + imageName;

  var onError = function (err) {
    if (err.failCode === 'Item not found') {
      callback(null, null);

    } else {
      callback(err);
    }
  };

  client.get(path, function (err, body, res) {
    return err
      ? onError(err)
      : callback(null, body);
  });
};

var deleteOSDisk = function (client, server, callback) {
  var diskName = null,
    path;

  if (server && server.RoleList && server.RoleList.Role) {
    if (server.RoleList.Role.OSVirtualHardDisk) {
      diskName = server.RoleList.Role.OSVirtualHardDisk.DiskName;
    }
  }

  if (diskName === null) {
    callback(null);
    return;
  }

  // https://management.core.windows.net/<subscription-id>/services/disks/<disk-name>
  path = client.subscriptionId + '/services/disks/' + diskName;

  client._request({
    method: 'DELETE',
    path: path
  }, function (err, body, res) {
    if (err) {
      return callback(err);
    }
    // poll azure for result of request
    pollRequestStatus(client, res.headers['x-ms-request-id'], MINIMUM_POLL_INTERVAL, callback);
  });
};

var deleteOSBlob = function (client, server, callback) {
  var blob = null;

  if (server && server.RoleList && server.RoleList.Role) {
    if (server.RoleList.Role.OSVirtualHardDisk) {
      blob = server.RoleList.Role.OSVirtualHardDisk.MediaLink;
    }
  }

  if (blob === null) {
    callback(null);
    return;
  }

  getStorageInfoFromUri(blob, function (err, info) {
    if (err) {
      callback(err);
    } else {
      var storage = pkgcloud.storage.createClient(client.config);
      storage.removeFile(info.container, info.file, function (err, result) {
        callback(err);
      });
    }
  });
};

/**
 * getServersFromServices
 * Retrieves all servers (VMs) from the list of services
 */
var getServersFromServices = function (client, services, callback) {
  var task = function (service, next) {
    getServersFromService(client, service.ServiceName, function (err, servers) {
      next(err, servers);
    });
  };

  // Check each service for deployed VMs.
  async.concat(services, task, function (err, servers) {
    callback(err, servers);
  });
};

/**
 * getServersFromServices
 * Retrieves all servers (VMs) from a Hosted Service
 */
var getServersFromService = function (client, serviceName, callback) {
  var servers = [];
  getHostedServiceProperties(client, serviceName, function (err, result) {
    if (err) {
      return callback(err);
    }

    if (result && result.Deployments && result.Deployments.Deployment) {
      if (isVM(result.Deployments.Deployment)) {
        servers.push(result.Deployments.Deployment);
      }
    }

    callback(null, servers);
  });
};

var isVM = function (deployment) {
  if (deployment.RoleList && deployment.RoleList.Role) {
    if (deployment.RoleList.Role.RoleType === 'PersistentVMRole') {
      return true;
    }
  }

  return false;
};

/**
 Get Hosted Service Properties
 GET https://management.core.windows.net/<subscription-id>/services/hostedservices/<service-name>?embed-detail=true
 A successful operation returns status code 200 (OK).
 */
var getHostedServiceProperties = function (client, serviceName, callback) {
  var path = client.subscriptionId + '/services/hostedservices/' + serviceName + '?embed-detail=true';

  var onError = function (err) {
    return err.failCode === 'Item not found'
      ? callback(null, null)
      : callback(err);
  };

  client.get(path, function (err, body, res) {
    return err
      ? onError(err)
      : callback(null, body);
  });
};

/**
 * pollRequestStatus
 * uses Get Operation Status
 * GET https://management.core.windows.net/<subscription-id>/operations/<request-id>
 */

var pollRequestStatus = function (client, requestId, interval, callback) {
  var checkStatus = function () {
    var path = client.subscriptionId + '/operations/' + requestId;
    client.get(path, function (err, body, res) {
      if (err) {
        return callback(err);
      }
      switch (body.Status) {
        case 'InProgress':
          setTimeout(checkStatus, interval);
          break;
        case 'Failed':
          callback(body.Error);
          break;
        case 'Succeeded':
          callback(null);
          break;
      }
    });
  };

  checkStatus();
};

var getStorageInfoFromUri = exports.getStorageInfoFromUri = function (uri, callback) {
  var u, tokens, path,
    info = {};

  u = URL.parse(uri);
  if (!u.host || !u.path) {
    return callback(errs.create({message: 'invalid Azure container or blob uri'}));
  }

  tokens = u.host.split('.');
  info.storage = tokens[0];

  path = u.path;
  // if necessary, remove leading '/' from path
  if (path.charAt(0) === '/') {
    path = path.substr(1);
  }
  tokens = path.split('/');
  info.container = tokens.shift();
  info.file = tokens.join('/');

  callback(null, info);
};

/**
 * createImage()
 * 1. Check if the server exists
 * 2. stop server if it is running
 * 3. capture server image
 */
var createImage = exports.createImage = function (client, serverName, targetImageName, callback) {
  async.waterfall([
    function (next) {
      // stop the server
      stopServer(client, serverName, next);
    },
    function (next) {
      // capture the server image
      captureServer(client, serverName, targetImageName, next);
    }],
    function (err) {
      callback(err, targetImageName);
    }
  );
};

/**
 * destroyImage()
 * 1. get the requested image
 * 2. delete the image using its label
 */
var destroyImage = exports.destroyImage = function (client, imageName, callback) {
  async.waterfall([
    function (next) {
      // stop the server
      client.getImage(client, imageName, next);
    },
    function (image, next) {
      deleteImage(client, image, next);
    }],
    function (err) {
      callback(err, imageName);
    }
  );
};

exports._updateMinimumPollInterval = function(interval) {
  MINIMUM_POLL_INTERVAL = interval;
};