
# Overview

For more information please refer to the main [Apiary](https://github.com/ExpediaInc/apiary) project page.

## Usage

Example module invocation:
```
module "apiary-authorization" {
  source            = "git::https://github.com/ExpediaInc/apiary-authorization.git?ref=master"
  aws_region        = "us-west-2"
  vpc_id            = "vpc-1"
  private_subnets   = ["subnet-1", "subnet-2"]

  tags = {
    Application = "Apiary-Authorization"
    Team = "Operations"
  }

  ranger_docker_image       = "docker_repo.mydomain.com/apiary-ranger"
  ranger_docker_version     = "latest"
  ranger_db_ingress_cidr    = ["10.0.0.0/8", "172.16.0.0/12"]
  ranger_admin_ingress_cidr = ["10.0.0.0/8", "172.16.0.0/12"]
  ranger_domain_name        = "mydomain.com"

  ldap_secret_name = "bind_credential"
  ldap_ca_cert     = "${base64encode(file("files/ldap_ca.crt"))}"
  ldap_url         = "ldaps://ldap_server.mydomain.com"
  ldap_base        = "dc=mydomain,dc=com"
  ldap_user_base   = "OU=All Users,DC=mydomain,DC=com"
  ldap_group_base  = "OU=Security Groups,DC=mydomain,DC=com"

}
```

# Notes

This module requires SSL certificate for ranger-admin in IAM,you can use following command to upload certificate.
```
aws iam upload-server-certificate --server-certificate-name ranger-admin.mydomain.com --certificate-body file://ranger-admin.mydomain.com.crt --private-key file://ranger-admin.mydomain.com.pem
```

# Contact

## Mailing List
If you would like to ask any questions about or discuss Apiary please join our mailing list at 

  [https://groups.google.com/forum/#!forum/apiary-user](https://groups.google.com/forum/#!forum/apiary-user)

# Legal
This project is available under the [Apache 2.0 License](http://www.apache.org/licenses/LICENSE-2.0.html).

Copyright 2018 Expedia Inc.
