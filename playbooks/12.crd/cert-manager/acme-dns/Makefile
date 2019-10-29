SA ?= ./service-account.json
ifeq ("$(wildcard $(SA))","")
  $(error $(SA) not found)
endif

create:
	$(eval key := service-account.json)
	kubectl create secret generic clouddns-service-account --from-file=$(key)=$(SA)
	kubectl apply -f issuer.yaml
	kubectl apply -f cert.yaml

update:
	kubectl apply -f issuer.yaml
	kubectl apply -f cert.yaml

clean:
	kubectl delete secret clouddns-service-account
	kubectl delete -f cert.yaml
	kubectl delete -f issuer.yaml