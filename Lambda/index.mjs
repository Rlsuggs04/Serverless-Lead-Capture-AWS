// Import the SES client and command for sending emails
import { SESClient, SendEmailCommand } from "@aws-sdk/client-ses";

// Import the DynamoDB client and document client for database operations
import { DynamoDBClient } from "@aws-sdk/client-dynamodb";

// DynamoDBDocumentClient is a higher level abstraction that simplifies
// working with DynamoDB by handling type marshalling automatically
import { DynamoDBDocumentClient, PutCommand } from "@aws-sdk/lib-dynamodb";

// Used to generate a unique ID for each form submission
import { randomUUID } from "crypto";

// Pull region and table name from environment variables set in Terraform
// Falls back to defaults if not set
const REGION = process.env.AWS_REGION || "us-east-1";
const TABLE_NAME = process.env.TABLE_NAME || "ContactMessages";

// Pull sender and receiver emails from environment variables set in Terraform
const RECEIVER = process.env.RECEIVER_EMAIL;
const SENDER   = process.env.SENDER_EMAIL;

// Initialize the SES and DynamoDB clients using the region
const ses = new SESClient({ region: REGION });
const ddb = DynamoDBDocumentClient.from(new DynamoDBClient({ region: REGION }));

// Regex pattern used to validate the email address submitted in the form
const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

export const handler = async (event) => {
  console.log("Received event:", JSON.stringify(event));

  try {
    // When API Gateway uses AWS_PROXY the body is passed as a JSON string
    // This line handles both cases — a raw string body or a pre-parsed object
    const body =
      typeof event?.body === "string" ? JSON.parse(event.body) :
      (event?.body ?? event ?? {});

    // Destructure the form fields from the parsed body
    // Default to empty strings if any field is missing
    const { name = "", phone = "", email = "", message = "" } = body;

    // Validate that the required fields are present before proceeding
    if (!name || !email) {
      return {
        statusCode: 400,
        headers: corsHeaders(),
        body: JSON.stringify({ error: "name and email are required" })
      };
    }

    // Generate a unique ID and timestamp for this submission
    const id = randomUUID();
    const ts = new Date().toISOString();

    // 1) Save the form submission to DynamoDB with all fields and metadata
    await ddb.send(new PutCommand({
      TableName: TABLE_NAME,
      Item: { id, name, phone, email, message, createdAt: ts }
    }));

    // 2) Build the SES email parameters using the submitted form data
    const params = {
      Destination: { ToAddresses: [RECEIVER] },
      Message: {
        Subject: { Data: `Website Query Form: ${name}`, Charset: "UTF-8" },
        Body: {
          Text: {
            Data:
                  `Full Name: ${name}
                  Phone: ${phone}
                  Email: ${email}
                  Message: ${message}
                  ID: ${id}
                  Time: ${ts}`,
            Charset: "UTF-8"
          }
        }
      },
      Source: SENDER
    };

    // Only add a Reply-To header if the submitted email passes validation
    // This allows you to reply directly to the person who submitted the form
    if (EMAIL_RE.test(email)) {
      params.ReplyToAddresses = [email];
    }

    // Send the email through SES
    await ses.send(new SendEmailCommand(params));

    // Return a success response with the generated submission ID
    return {
      statusCode: 200,
      headers: corsHeaders(),
      body: JSON.stringify({ ok: true, id })
    };

  } catch (err) {
    // Log the error to CloudWatch and return a 500 response
    console.error("Error:", err);
    return {
      statusCode: 500,
      headers: corsHeaders(),
      body: JSON.stringify({ error: "Internal error" })
    };
  }
};

// Returns the CORS headers required for all responses so the browser
// allows the API call from a different origin
function corsHeaders() {
  return {
    "Content-Type": "application/json",
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "OPTIONS,POST",
    "Access-Control-Allow-Headers":
      "Content-Type,Authorization,X-Api-Key,X-Amz-Date,X-Amz-Security-Token"
  };
}