#!/bin/bash

AMI_ID="ami-09c813fb71547fc4f"
SG_ID="sg-098df78dccd68a321"
INSTANCES=("mongodb","redis","catalogue","mysql","rabbitmq","user","cart","payment","shipping",
"dispatch","frontend")
ZONE_ID=Z05916843N3ELVCBEEJL2
DOMAIN_NAME="vishnuv8.fun"
