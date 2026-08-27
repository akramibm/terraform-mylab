variable "allowed_ports" {

    type = list(string)
    description = "List of allowed ports"
    default = [ "22", "80", "443", "3306" ]


  
}