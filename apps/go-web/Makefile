build: 
	gcloud builds submit --config=cloudbuild.yaml

build-deploy: 
	skaffold run -p gcb

build-local:
	docker build -t go-web:local .
