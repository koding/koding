# Class: yumrepos
#
#
define  yumrepos ($repo) {
    case $repo {
         'epel': {
            include yumrepos::epel
         }
         'ius': {
            include yumrepos::ius
         }
         'koding': {
            include yumrepos::koding
         }
         'erlang': {
            include yumrepos::erlang
         }
         'zabbixzone': {
            include yumrepos::zabbixzone
         }
         'erlang': {
            include yumrepos::erlang
         }




    }
}
