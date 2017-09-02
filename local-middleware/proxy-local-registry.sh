#!/bin/sh

ssh -i ~/.minikube/machines/minikube/id_rsa -N -L '*:5000:localhost:5000' docker@$(minikube ip)

# kubectl port-forward --namespace kube-system $(kubectl get po -n kube-system | grep kube-registry-v0 | awk '{print $1;}') 5000:5000
