# coredns 增加容器内部域名解析

## 这么做的原因

容器内部的服务可能需要通过域名访问一个服务。但是这个域名是公网域名，
甚至这个域名服务配置了https证书，导致无法通过内网ip地址+端口方式访问(证书验证错误)。

为了防止请求从公网兜一圈回来，减少请求耗时，将域名解析为内网ip地址是最合适的方式。

为了到达这个目的，有2个方式可以实现

1. 修改容器内部hosts文件，增加一条解析记录

可以通过dockerfile实现，也可以使用kubernetes initContainer机制在容器初始化时修改

优势： 非常简单就可以实现，只需要修改/etc/hosts 文件

劣势:  将容器和容器的运行环境锁在一起，违背了一个容器到处运行的docker理念。
在其他环境下，配置的内网解析可能无法使用

2. 配置kubernetes dns服务，增加一条域名解析

优势： 和容器无关，和环境有关

劣势： 配置相对复杂，麻烦


## coredns 增加域名解析

案例： 有一个域名 api.domain.com 需要指向到192.168.0.101

1. 修改kubernetes coredns 的configmap


修改Corefile 文件，增加了一条配置记录
```
    api.domain.com:53 {
        file /etc/coredns/api.domain.com
        log
    }
```

新增api.domain.com文件
```
    $ORIGIN api.domain.com.
    @ 3600 IN SOA sns.dns.icann.org. noc.dns.icann.org. (
            2017042745 ; serial
            7200       ; refresh (2 hours)
            3600       ; retry (1 hour)
            1209600    ; expire (2 weeks)
            3600       ; minimum (1 hour)
            )

      3600 IN NS a.iana-servers.net.
      3600 IN NS b.iana-servers.net.    
            IN A     192.168.0.101
            IN AAAA  ::1
```


最终效果如下：
```

  Corefile: |
    api.domain.com:53 {
        file /etc/coredns/api.domain.com
        log
    }
    .:53 {
        errors
        health
        kubernetes cluster.local in-addr.arpa ip6.arpa {
           pods insecure
           upstream
           fallthrough in-addr.arpa ip6.arpa
        }
        prometheus :9153
        proxy . /etc/resolv.conf
        cache 30
    }

  api.domain.com: |
    $ORIGIN api.domain.com.
    @ 3600 IN SOA sns.dns.icann.org. noc.dns.icann.org. (
            2017042745 ; serial
            7200       ; refresh (2 hours)
            3600       ; retry (1 hour)
            1209600    ; expire (2 weeks)
            3600       ; minimum (1 hour)
            )

      3600 IN NS a.iana-servers.net.
      3600 IN NS b.iana-servers.net.    
            IN A     192.168.0.101
            IN AAAA  ::1
``` 

2. 修改coredns deploy文件，将configmap 内的api.domain.com 文件挂载到容器内
```
      volumes:
      - configMap:
          defaultMode: 420
          items:
          - key: Corefile
            path: Corefile
          - key: api.domain.com
            path: api.domain.com
          name: coredns
```

等待coredns 容器重启后生效