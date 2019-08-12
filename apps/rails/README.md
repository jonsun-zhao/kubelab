# App: rails

## Build the image

```sh
make build
```

## Debug locally

```sh
docker run --name db -e MYSQL_ALLOW_EMPTY_PASSWORD=yes -d -p 3306:3306 mysql:5.7; sleep 5

pushd ./src
RAILS_ENV=development ./run.sh
pop
```
