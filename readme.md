# SingleServerGcloud

Terraform module. Basically I'm using this as a shortcut to create gcloud apps with 1 server with ssl certs and stuff.


#### Usage

```hcl
module "auto-single-lb" {
  source = "git::github.com/RobertAron/SingleServerGcloud?ref=v0.4"
  image  = "gcr.io/lightbikenode/light-bike"
  domain = "light.bike.robertaron.io"
}
```