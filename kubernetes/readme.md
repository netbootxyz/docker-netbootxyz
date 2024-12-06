# Kubernetes Deployment example
This is an example of one possibilty how to deploy netboot.xyz to a OKD/OpenShift cluster.
You can also use it for a Kubernetes cluster, but in this case you will add your ingress configuration instead of the route.

## Edit PVC config
First edit both pvc (pvc.yaml and pvc-config.yaml) configs, so that they reference your storage-class.

## Edit Route config (for OKD/OpenShift)
Edit the host to your needs.
```
spec:
  host: pxeboot.apps.cluster.local
```

## Optional edit PXE-Bootserver-Conf
Optionaly you can edit the pxe-bootserver-conf.yaml for your needs.

## Deploy to Kubernetes or OKD/OpenShift
### create a namespace
```
kubectl create ns pxeboot
```
### deploy
```
kubectl -n pxeboot apply -f pvc.yaml
kubectl -n pxeboot apply -f pvc-config.yaml
kubectl -n pxeboot apply -f pxe-bootserver-conf.yaml
kubectl -n pxeboot apply -f serviceaccount.yaml
kubectl -n pxeboot apply -f deployment.yaml
kubectl -n pxeboot apply -f route.yaml
kubectl -n pxeboot apply -f service.yaml
```

## Check if netboot.xyz is running
### Check Deployment, Service and Pod
```
kubectl -n pxeboot get all

NAME                                        READY   STATUS    RESTARTS   AGE
pod/pxe-bootserver-ds-5559fd7-4ncjb         1/1     Running   0          2d23h

NAME                               TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)                  AGE
service/svc-pxe-bootserver         ClusterIP   172.30.255.66    <none>        80/TCP,3000/TCP,69/UDP   11d

NAME                                   READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/pxe-bootserver-ds      1/1     1            1           3d7h

NAME                                              DESIRED   CURRENT   READY   AGE
replicaset.apps/pxe-bootserver-ds-5559fd7         1         1         1       2d23h

NAME                                                  HOST/PORT                           PATH   SERVICES                   PORT    TERMINATION   WILDCARD
route.route.openshift.io/pxe-bootserver-route         pxeboot.apps.cluster.local                 svc-pxe-bootserver         3000    edge          None
```
### Check the logs of the Pod
```
kubectl -n pxeboot logs pxe-bootserver-ds-5559fd7-4ncjb

chown: /config/nginx/nginx.conf: Read-only file system
            _   _                 _
 _ __   ___| |_| |__   ___   ___ | |_  __  ___   _ ____
| '_ \ / _ \ __| '_ \ / _ \ / _ \| __| \ \/ / | | |_  /
| | | |  __/ |_| |_) | (_) | (_) | |_ _ >  <| |_| |/ /
|_| |_|\___|\__|_.__/ \___/ \___/ \__(_)_/\_\__,  /___|
                                             |___/
2024-12-03 16:40:33,309 INFO Set uid to user 0 succeeded
2024-12-03 16:40:33,322 CRIT could not write pidfile /supervisord.pid
2024-12-03 16:40:34,326 INFO spawned: 'syslog-ng' with pid 13
2024-12-03 16:40:34,330 INFO spawned: 'nginx' with pid 14
2024-12-03 16:40:34,333 INFO spawned: 'webapp' with pid 15
2024-12-03 16:40:34,336 INFO spawned: 'dnsmasq' with pid 16
2024-12-03 16:40:34,340 INFO spawned: 'messages-log' with pid 17
2024-12-03 16:40:34,348 WARN exited: messages-log (exit status 1; not expected)
2024-12-03 16:40:34,367 WARN exited: syslog-ng (exit status 2; not expected)
2024-12-03 16:40:35,714 INFO spawned: 'syslog-ng' with pid 28
2024-12-03 16:40:35,715 INFO success: nginx entered RUNNING state, process has stayed up for > than 1 seconds (startsecs)
2024-12-03 16:40:35,715 INFO success: webapp entered RUNNING state, process has stayed up for > than 1 seconds (startsecs)
2024-12-03 16:40:35,715 INFO success: dnsmasq entered RUNNING state, process has stayed up for > than 1 seconds (startsecs)
2024-12-03 16:40:35,718 INFO spawned: 'messages-log' with pid 29
2024-12-03 16:40:35,726 WARN exited: messages-log (exit status 1; not expected)
2024-12-03 16:40:35,754 WARN exited: syslog-ng (exit status 2; not expected)
2024-12-03 16:40:37,760 INFO spawned: 'syslog-ng' with pid 30
2024-12-03 16:40:37,763 INFO spawned: 'messages-log' with pid 31
2024-12-03 16:40:37,771 WARN exited: messages-log (exit status 1; not expected)
2024-12-03 16:40:37,802 WARN exited: syslog-ng (exit status 2; not expected)
2024-12-03 16:40:40,938 INFO spawned: 'syslog-ng' with pid 36
2024-12-03 16:40:40,941 INFO spawned: 'messages-log' with pid 37
2024-12-03 16:40:40,950 WARN exited: messages-log (exit status 1; not expected)
2024-12-03 16:40:40,950 INFO gave up: messages-log entered FATAL state, too many start retries too quickly
2024-12-03 16:40:40,981 WARN exited: syslog-ng (exit status 2; not expected)
2024-12-03 16:40:41,983 INFO gave up: syslog-ng entered FATAL state, too many start retries too quickly
```
