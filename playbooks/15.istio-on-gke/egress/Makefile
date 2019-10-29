apply:
	kubectl apply -f app.yaml
	kubectl apply -f service.yaml

clean:
	-kubectl delete -f app.yaml
	-kubectl delete -f service.yaml
	-kubectl delete -f destination_rule.yaml