# Application Definition
app_name        = "batcloud" # Do NOT enter any spaces
app_environment = "test"     # Dev, Test, Prod, etc

#AWS authentication variables
aws_key_pair_name = "batcloud-key-pair"
#aws_key_pair_file = "kopicloud-key-pair.pem"
aws_region = "us-east-2"

# Application access
app_sources_cidr   = ["0.0.0.0/0"] # Specify a list of IPv4 IPs/CIDRs which can access app load balancers
admin_sources_cidr = ["0.0.0.0/0"] # Specify a list of IPv4 IPs/CIDRs which can admin instances
