# Creates a DynamoDB table named ContactMessages to store lead capture form submissions
# The table uses a single partition key (id) of type String to uniquely identify each entry
# PAY_PER_REQUEST billing means we only pay per read/write operation with no upfront capacity planning
resource "aws_dynamodb_table" "contact_messages" {
  name         = "ContactMessages"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"                                 #The partition key that uniquely identifies each item in the table.

  attribute {
    name = "id"
    type = "S"
  }

  tags = {
    Name = "epicreads-contact-messages"
  }
}

# Outputs the DynamoDB table name for reference in other resources such as Lambda
output "dynamodb_table_name" {
  value = aws_dynamodb_table.contact_messages.name
}