#
# Module: static_nginx
#
#  Created by  on 2012-03-02.
#  Copyright (c) 2012 Koding. All rights reserved.
#

# Class: static_nginx
#
#
class static_nginx {
    include static_nginx::install, static_nginx::config, static_nginx::service, static_nginx::repo
}
