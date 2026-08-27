resource "aws_security_group" "name" {

    name = "multi-inbound-rules-diff-source"
    description = "Security group with multiple inbound rules for different sources"

    dynamic "ingress" {
        for_each = var.allowed_ports
        content {
            description = "Allowed port ${ingress.key}"
            from_port   = ingress.key
            to_port     = ingress.key
            protocol    = "tcp"
            cidr_blocks = [ingress.value]
            self       = false
            ipv6_cidr_blocks = []
            security_groups = []
            prefix_list_ids = []
        }
        
      
    }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
}
}