build:
	gcloud builds submit --config=cloudbuild.yaml

build-local:
	docker build -t rails:local .

run-local:
	docker run --name db -e MYSQL_ALLOW_EMPTY_PASSWORD=yes -d -p 3306:3306 mysql:5.7; sleep 5; \
	docker run --name app -p 3000:3000 -d --link db -e DB_HOST=db -e SECRET_KEY_BASE=638c154e420ab0af7830dd48922788 -e RAILS_ENV=development rails:local

clean-local:
	docker stop app && docker rm app; \
	docker stop db && docker rm db