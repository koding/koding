class hosting_crontabs {

    include hosting_crontabs::scripts_dir

    include hosting_crontabs::clamav    
    include hosting_crontabs::phishing
    include hosting_crontabs::aide
    include hosting_crontabs::mysql_quota
    include hosting_crontabs::mysql_total_size
    include hosting_crontabs::gem_update
    include hosting_crontabs::ebs_snapshots
    include hosting_crontabs::mail_queue
    include hosting_crontabs::check_account

}
