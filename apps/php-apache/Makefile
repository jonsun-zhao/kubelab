build:
	gcloud builds submit --config=cloudbuild.yaml

build-skaffold:
	skaffold run -p gcb

build-local:
	docker build -t php-apache:local .