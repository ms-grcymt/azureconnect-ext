# How to test staff
## How to test tripviewer can access userprofile

```bash
kubectl exec -it tripviewer-deploy-79f86696c9-gptrf -n web -- /bin/sh
curl -i -X GET 'http://userprofile.api.svc.cluster.local/api/user'
```
if we see issues connectiong then check the pod and the logs, i.e.

```bash
kubectl describe pod mydrive-user-deployment-7df58786f7-66v8s -n api
# get the logs
kubectl logs mydrive-user-deployment-7df58786f7-66v8s -n api
```


