Description
===========
This is a cookbook for managing RabbitMQ with Chef.  It uses the default settings, but can also be configured via attributes.

Recipes
=======
default
-------
Installs `rabbitmq-server` from RabbitMQ.com's APT repository, your distro's version, or the DEB or RPM directly (there is no yum repo). Depending on your distribution, the provided version may be quite old so they are disabled by default. If you want to use the distro version, set the attribute `['rabbitmq']['use_distro_version']` to `true`.

Cluster recipe is now combined with default. Recipe will now auto-cluster. Set the :cluster attribute to true, :cluster_disk_nodes array of `node@host` strings that describe which you want to be disk nodes and then set an alphanumeric string for the :erlang_cookie.

To enable SSL turn :ssl to true and set the paths to your cacert, cert and key files.

Resources/Providers
===================
There are 3 LWRPs for interacting with RabbitMQ.

user
----
Adds and deletes users, fairly simplistic permissions management.

- `:add` adds a `user` with a `password`
- `:delete` deletes a `user`
- `:set_permissions` sets the `permissions` for a `user`, `vhost` is optional
- `:clear_permissions` clears the permissions for a `user`

### Examples
``` ruby
rabbitmq_user "guest" do
  action :delete
end

rabbitmq_user "nova" do
  password "sekret"
  action :add
end

rabbitmq_user "nova" do
  vhost "/nova"
  permissions "\".*\" \".*\" \".*\""
  action :set_permissions
end
```

vhost
-----
Adds and deletes vhosts.

- `:add` adds a `vhost`
- `:delete` deletes a `vhost`

### Example
``` ruby
rabbitmq_vhost "/nova" do
  action :add
end
```

plugin
-----
Enables or disables a rabbitmq plugin.

- `:enable` enables a `plugin`
- `:disable` disables a `plugin`

### Example
``` ruby
rabbitmq_plugin "rabbitmq_stomp" do
  action :enable
end

rabbitmq_plugin "rabbitmq_shovel" do
  action :disable
end
```

Limitations
===========
For an already running cluster, these actions still require manual intervention:
- changing the :erlang_cookie
- turning :cluster from true to false

The rabbitmq::chef recipe was only used for the chef-server cookbook and has been moved to chef-server::rabbitmq.

License and Author
==================

Author:: Benjamin Black <b@b3k.us>
Author:: Daniel DeLeo <dan@kallistec.com>
Author:: Matt Ray <matt@opscode.com>

Copyright:: 2009-2012 Opscode, Inc

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
