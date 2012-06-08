#
# Module: deploy_from_s3
#
#  Created by  on 2012-03-13.
#  Copyright (c) 2012 Koding. All rights reserved.
#
# Class: deploy_from_s3
#
#
class deploy_from_s3 {
    include deploy_from_s3::yumrepo,deploy_from_s3::install_tools
}
