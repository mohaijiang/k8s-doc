## gitlab 配置mysql
```
sudo docker run --detach \
    --hostname gitlab.example.com \
    --publish 443:443 --publish 80:80 --publish 22:22 \
    --env GITLAB_OMNIBUS_CONFIG="external_url 'http://gitlab.192.168.2.231.nip.io/'; postgresql['enable'] = false; gitlab_rails['db_adapter'] = 'mysql2';gitlab_rails['db_encoding'] = 'utf8';gitlab_rails['db_host'] = '192.168.2.231';gitlab_rails['db_port'] = 3306;gitlab_rails['db_username'] = 'root';gitlab_rails['db_password'] = 'abcd1234';gitlab_rails['redis_host'] = '192.168.2.231';" \
    --name gitlab \
    --restart always \
    --volume /srv/gitlab/config:/etc/gitlab \
    --volume /srv/gitlab/logs:/var/log/gitlab \
    --volume /srv/gitlab/data:/var/opt/gitlab \
    gitlab/gitlab-ce:latest
```