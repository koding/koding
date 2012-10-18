#
# Module: pure-ftpd
#
#  Created by  on 2012-03-02.
#  Copyright (c) 2012 Koding. All rights reserved.
#

# Class: pure-ftpd
#
#
class pure-ftpd {
    include pure-ftpd::install
    include pure-ftpd::config
    include pure-ftpd::service
    include pure-ftpd::authapp
    include pure-ftpd::scripts
}
