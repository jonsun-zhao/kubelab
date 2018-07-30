### encode variables

```sh
$ echo -n 'http://35.227.201.159/test/' | base64
aHR0cDovLzM1LjIyNy4yMDEuMTU5L3Rlc3Qv

$ echo -n 'User-Agent: Job Runner/1.0' | base64
VXNlci1BZ2VudDogSm9iIFJ1bm5lci8xLjA=
```
### create secret

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: mysecret
type: Opaque
data:
  url: aHR0cDovLzM1LjIyNy4yMDEuMTU5L3Rlc3Qv
  user_agent: VXNlci1BZ2VudDogSm9iIFJ1bm5lci8xLjA=
```
