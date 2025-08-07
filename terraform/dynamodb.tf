resource "aws_dynamodb_table" "table_data" {
  name = var.dynamodb_table_name

  hash_key  = "PK"
  range_key = "SK"

  # All keys (primary and secondary) must be defined in the attribute block.
  # This section defines the data types for each key attribute.
  attribute {
    name = "PK"
    type = "S" # S for String, N for Number, B for Binary
  }

  attribute {
    name = "SK"
    type = "S"
  }


  # Attributes for the Global Secondary Index (GSI)
  attribute {
    name = var.gsi_hash_key
    type = "S"
  }

  global_secondary_index {
    name     = var.gsi_name
    hash_key = var.gsi_hash_key

    # "ALL" copies all attributes.
    projection_type = "ALL"
  }

  ttl {
    attribute_name = "expiration_time"
    enabled        = true
  }

  billing_mode = "PAY_PER_REQUEST"

}
