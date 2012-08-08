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
    include pure-ftpd::install, pure-ftpd::config, pure-ftpd::service, pure-ftpd::authapp
}
