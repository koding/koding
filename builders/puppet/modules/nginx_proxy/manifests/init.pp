#
# Module: nginx_proxy
#
#  Created by  on 2012-03-02.
#  Copyright (c) 2012 Koding. All rights reserved.
#

# Class: nginx_proxy
#
#
class nginx_proxy {
    include nginx_proxy::install, nginx_proxy::config, nginx_proxy::service, nginx_proxy::repo
}
