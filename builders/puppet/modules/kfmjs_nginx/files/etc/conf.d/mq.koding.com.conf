upstream mq_backend  {
    server localhost:8008;
    keepalive 32;
}


server {
    listen       443;
    server_name  mq.koding.com;

    ssl      on;
    ssl_certificate      /etc/nginx/ssl/server.crt;
    ssl_certificate_key  /etc/nginx/ssl/server.key;
    ssl_protocols        SSLv3 TLSv1 TLSv1.1 TLSv1.2;
    ssl_session_cache    shared:SSL:10m;
    ssl_prefer_server_ciphers on;
    ssl_session_timeout  10m;
    #ssl_ciphers ALL:!kEDH!ADH:RC4+RSA:+HIGH:+MEDIUM:+LOW:+SSLv2:+EXP;
    ssl_ciphers ECDHE-RSA-AES256-SHA384:AES256-SHA256:RC4:HIGH:!MD5:!aNULL:!EDH:!AESGCM;
    ssl_ecdh_curve secp224r1;

    access_log  /var/log/nginx/mq.access.log  main;
    error_log   /var/log/nginx/mq.error.log;

    autoindex off;
    server_tokens off;

    #root /mnt/storage0/koding/website;

    location / {

        proxy_set_header X-Forwarded-Host $host;
        proxy_set_header X-Forwarded-Server $host;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for; 
        proxy_pass http://mq_backend;
        proxy_http_version 1.1;

    }


}
