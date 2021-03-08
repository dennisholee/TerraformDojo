provider aws {
  profile = "default"
  alias  = "region-one"
  region = "us-east-1" 
}

provider aws {
  alias  = "region-two"
  region = "us-west-2"
}
