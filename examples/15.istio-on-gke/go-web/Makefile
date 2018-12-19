apply:
	kubectl apply -f namespace.yaml
	kubectl apply -f app.yaml
	kubectl apply -f gateway.yaml
	kubectl apply -f destination-rule.yaml
	kubectl apply -f vs.yaml

clean:
	kubectl delete -f app.yaml
	kubectl -n istio-system delete service istio-ingressgateway
