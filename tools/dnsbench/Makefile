workspace = /tmp/dnsbench_build

build:
	gcloud builds submit --config=cloudbuild.yaml

build-local:
	cloud-build-local --config=cloudbuild.yaml --dryrun=false --write-workspace=$(workspace) .

clean-local:
	rm -rf ${workspace}