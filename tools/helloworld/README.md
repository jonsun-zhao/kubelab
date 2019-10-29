# Helloworld

[upstream](https://github.com/istio/istio/tree/master/samples/helloworld)

## Endpoints

* `/hello`
  * do some computation that loads up the CPU
  * print `'Hello version: %s, instance: %s\n' % (version, os.environ.get('HOSTNAME'))`

* `/health`
  * print `Helloworld is healthy` and return `200`