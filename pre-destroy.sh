#!/bin/bash

kubectl delete ingress app-ingress
sleep 120  # wait for LB controller to clean up
terraform destroy
