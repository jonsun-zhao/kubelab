workspace = /tmp/dnsbench_build

build:
	gcloud builds submit --config=cloudbuild.yaml

clean-local:
	-rm -rf ${workspace}

build-local: clean-local
	cloud-build-local --config=cloudbuild.yaml --dryrun=false --write-workspace=$(workspace) .

