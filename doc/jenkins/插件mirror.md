## 配置jenkins插件mirror
1: 修改  $JENKINS_HOME/hudson.model.UpdateCenter.xml

```
<?xml version='1.1' encoding='UTF-8'?>
<sites>
<site>
<id>default</id>
<url>https://updates.jenkins-zh.cn/update-center.json</url>
</site>　　
```

2: 下载证书到 $JENKINS_HOME/war/WEB-INF/update-center-rootCAs/

wget  https://raw.githubusercontent.com/jenkins-zh/mirror-adapter/master/rootCA/mirror-adapter.crt 

删除插件缓存$JENKINS_HOME/updates

镜像和为什么下载证书，到https://community.jenkins-zh.cn 学习
