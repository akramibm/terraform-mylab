# Create multiple inbound rules for the same source.
resource "aws_security_group" "name" {
  name        = "multi-inbound-rules-same-source"
  description = "Security group with multiple inbound rules for the same source"

  ingress = [

    for port in var.allowed_ports : {

    
      description = "Allowed port "
      from_port   = port
      to_port     = port
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      self       = false
      ipv6_cidr_blocks = []
      security_groups = []
      prefix_list_ids = []

    }
  
  ]

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "multi-inbound-rules-same-source"
  }
}
