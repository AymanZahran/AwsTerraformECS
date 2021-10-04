resource "aws_security_group" "webserver_security_group" {
  name        = var.sg_webserver
  description = "Allow Traffic to Web Servers"
  vpc_id      = var.vpc_id

  # ingress {
  #   from_port   = 443
  #   to_port     = 443
  #   protocol    = "TCP"
  #   cidr_blocks = ["10.0.0.0/16"]
  # }

  # ingress {
  #   from_port   = 80
  #   to_port     = 80
  #   protocol    = "TCP"
  #   cidr_blocks = ["10.0.0.0/16"]
  # }

  # #  ingress {
  # #    from_port   = 80  #ALB is using the Inline LB not OneArm LB so the source port is the client port
  # #    to_port     = 80 #For Internal Security Purposes
  # #    protocol    = "TCP"
  # #    cidr_blocks = ["0.0.0.0/0"]
  # #  }

  ingress {
     from_port   = 0
     to_port     = 0
     protocol    = "-1"
     cidr_blocks = ["0.0.0.0/0"]
   }

   egress {
     from_port   = 0
     to_port     = 0
     protocol    = "-1"
     cidr_blocks = ["0.0.0.0/0"]
    }

  tags = merge(
    var.tags,
    {
      "Name" = var.sg_webserver
    },
  )
}


