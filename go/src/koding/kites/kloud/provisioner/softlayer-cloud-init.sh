#!/bin/bash

# NOTE: If you modify this script remember about uploading it to the AWS bucket:
#
#  https://s3.amazonaws.com/koding-softlayer/softlayer-cloud-init.sh
#
# Ensure you granted download permission for everyone.

set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

# metadata <field>
metadata() {
	curl -sSL "https://api.service.softlayer.com/rest/v3/SoftLayer_Resource_Metadata/getUserMetadata.txt" | jq -r ".${1}"
}

# main
main() {
	apt-get install -y jq &>/dev/null || apt-get update # lazy update
	apt-get install -y cloud-init curl jq patch bzip2

	# patch cloud-init with Softlayer support:
	#
	#  https://bazaar.launchpad.net/~stanislav-turlo/cloud-init/softlayer-support-0.7.2/revision/1050
	#
	pushd /usr/lib/python2.7/dist-packages/

	# patch generated with:
	#
	#   curl -sSL 'https://bazaar.launchpad.net/~stanislav-turlo/cloud-init/softlayer-support-0.7.2/diff/1050?context=3' | bzip2 -9 - | base64 -b 80
	#
	(base64 -d | bzip2 -d | patch -p0) <<EOF
QlpoOTFBWSZTWdVMKuMAAeZfgGZweO//v3/v/qq////qUAWbe7BOgXXbDd247mFBKIjRE8Jk0amGjRJp
k2iZPSNPFNGm9U9TQaabSaAlNSaYjImmSNT0jT1PUDRpoaaBkNAAaA0ASJBNCGqfomp4TKm9U9Rk9T1B
oGjIGgADQMhxkaZMTQZMmE0yBkNAaA0yaGAE0BhJIRqn6mqfoap+qfpqh6jeonkn6QINpMgMjCDQZMGw
LISP+DPvM7H1P7F9Gz0U9HZvTtaMG7r4PVNQxjVnsXaW4Kz31M6eFKXYZGN74C+HNVVoOiSJMMw9DDIw
YRDwYaZkJkMBjObGblXUcztGU2mawv0KVp4RZdnng1PUj2LdetdHPZtqnkj2zWw+qV8/4SamDXLofSWO
3FC998+emzfMuay39Rsku5ml+/vzh5uBLXhO51+Dx1+/cVQrg5nvIA6ZVVAsdHC2p22Yz4axRt2nymVt
XKSfWDivGEaRgh5BW2NGBPEzSXQgXFrlpr4X6fTCUsoB5w0sBxptGRhuTxr5+tYHJDbS0a24hJlugmpT
PqlfbL8lkrJKvVVyhH3H04pwUna+MYDUIGEIvGQx4LmL8xPvW7De6Vyl/8tNUPUugLhM8/YMOXmfp2de
mujPj+0HFO4Ld0NWLGrMWvkhgE0sgFRRrN1vjUmfOgcGDbG6itEeqQq9tfweDQw7Q6S6VCSKLUOrXKpU
kO6E5fhcWakpKvnbwHmrupXRW0feGLINYzuZoEuy8PVkyVY88B6LzFWXZfS8oqqpYqFpWmgl4q67AgHE
7O3v7G+86fLcwems+ZD+39Y45Aa6ZObtueBs7jGeMy0RG4WpSxrJlCyN9d27CyLCOhMCXLRgPZyojkVe
yWfLCzId6LwwleMnu0SUZobZQyYUJD14HOc2+jw0HQSOL2Z1SuK7pzIZ3utEfkzR1TUjIlfqLbE8jNQb
951amWFTfJZR+JZ0LwxU8Y0cR31mM2+VFPFj1+4UO7kVCv3lPdTyNaMftRKRhN2qxkMSIbMhM+mEGlhX
2suHq9ZWJ9SjTdHNyKmdRVZWWI9STJKpo0BKmJ3KzDbjfsFLZ5CjWtqPBhNzaW6A9MgbUZAbOlIp26M1
ELdYc+4MVFF89b35xEZK9MjEOphGb75K1O0xOR1h74lAiYogu0JwoYrj43eEtqyopOHRmdvPWfGP7upX
iuU2oMIFDnIpfu0aL5GJdJnGCqHgxBZWQO+hr1I+FWC6iInIl4/xam054SyUEsIyL1DE2u3IJYBn5BiN
P5I49zuVlew1/w6d8ZqhdIkuAg5ozJlykNdAioi1NsnmFTLZa0GiPFyVvaLU0oSYRJMGNzb3fHmyDuwQ
gbCKkh5uyVTl9CVvGjdt9ixGEqeW0cEt2EvMoMShS3PYaioEWllsIEjOGMHg/IGhzgJIcV/Gou89tuta
Avz1NvVuCBi95YMG0xwdOdWGe+Vj2h3SgxNoPMuAQTScKDgRyvIoLEWhE1eLOrC+6AnLeRSCNYW9i1yf
egbUWC6ScMGwWE3MJTiem9TxMvEQXiyS2t59GUXpYWH78ZHjObuifgHvNPX2UuYaqkIB9Ne9y6ZAR/TS
iUiI3MxMOmWM048qESZaBHJamvL8ASYYtCY8z3MMDmScwtdXZzMhEDDO0qTJRe81e17DNilUZR1IFLAQ
PIaq8CMU8UO3Xxg0JBxjaPdATO14w3wki/eqSDTjke9bon8+7gdXNEg3veNwOtCu2+7guqOXO6WvfDb1
Q9UXqioXkPDvhAVNpql4YgLanlhI+WkD6BTGQo380rXUIKO8BdfZISnMUI7tJcgzms5VhCpKSjko0XhV
TIDxShJVjARMgTVDfDSq1AFXF2ZqGQjOWN5YKoB6Tw3M4T69tN2yhlQ7cSYotUmGYZxGhl/TADCZvI9X
/i7kinChIaqYVcY=
EOF

	popd

	# koding user metadata
	metadata "cloudInit" | base64 -d > /etc/cloud/cloud.cfg.d/99_koding.cfg

	# ensure cloud-init uses proper metadata source
	cat >/etc/cloud/cloud.cfg.d/90_dpkg.cfg <<EOF
# overwritten by Koding Userdata, to restore original value run dpkg-reconfigure cloud-init
datasource_list: [ SoftLayer, None ]
EOF

	# ensure cloud-init is started for the first time
	rm -rf /var/lib/cloud/*

	# update environment after cloud-init package installation
	source /etc/environment

	# run cloud-init
	cloud-init init --local
	cloud-init init
	cloud-init modules --mode=config
	cloud-init modules --mode=final

	# restore /etc/apt/sources.list from hackathon2016/etc/apt/sources.list
	# the following was generated with:
	#
	#   cat etc/apt/sources.list | bzip -9 - | base -b 80
	#
	(base64 -d | bzip2 -d) > /etc/apt/sources <<EOF
QlpoOTFBWSZTWWeE62AAALTZgAAQQAOAED5v36AwAUwANU/9VJGmajTJgmCgAADJkBSlRoNTKep+ppph
K2VREooiJhUAANuoSBpLPSN+9mDhGLyjkjRHZHZHhHlGLqv1HJHRGseEd0YtC5rZHUtkfSNy9L/o9lvR
vXRd0fiOCN6/V9o3Li45mYzMzcj0j7XtGq8Ixd1+I4C2R8RqjojReEbRqtFouiOKPpG5HIuCMFoq9roj
I3rkjotl5XNHVdUfEfaNUduGZjGZmS4o2R3XNfEdl/lsjUsRzSdkfwu5IpwoSDPCdbAA
EOF

	# update the index so the user don't have to do it manually
	apt-get update -q
}

main 2>&1 | tee -a /var/log/softlayer-cloud-init.log
