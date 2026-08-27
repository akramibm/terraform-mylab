variable "allowed_ports" {

    type = map(string)
    description = "example of sg multi inbound rules"
    default = {
      "22" = "203.0.113.0/24"
      "80" = "0.0.0.0/0"
      "443" = "0.0.0.0/0"
      "3306"  = "10.0.1.0/24"
    }
  
}