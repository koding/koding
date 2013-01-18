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

    include nginx_proxy::install
    include nginx_proxy::config
    include nginx_proxy::service
    include nginx_proxy::repo
    include nginx_proxy::user
    include nginx_proxy::cert

}
