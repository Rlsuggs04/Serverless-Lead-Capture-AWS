// This Lambda function is a contact form handler that receives form data from the frontend, constructs an email, and sends it using AWS SES.
//When triggered it receives an event object containing the form data (name, phone, email, message). 
// It then constructs an email with this information and sends it to a specified receiver email address using AWS SES. Finally, it returns a success response to the frontend.
import { SESClient, SendEmailCommand } from "@aws-sdk/client-ses";

const ses = new SESClient({ region: "us-east-1" });

const RECEIVER = process.env.RECEIVER_EMAIL;
const SENDER = process.env.SENDER_EMAIL;

export const handler = async (event) => {
  console.log("Received event:", event);

  const body = JSON.parse(event.body);

  const params = {
    Destination: { ToAddresses: [RECEIVER] },
    Message: {
      Body: {
        Text: {
          Data: `Full Name: ${body.name}
                Phone: ${body.phone}
                Email: ${body.email}
                Message: ${body.message}`,
          Charset: "UTF-8",
        },
      },
      Subject: { Data: `Website Query Form: ${body.name}`, Charset: "UTF-8" },
    },
    Source: SENDER,
  };

  await ses.send(new SendEmailCommand(params));

  return {
    statusCode: 200,
    headers: {
      "Content-Type": "application/json",
      "Access-Control-Allow-Origin": "*",
    },
    body: JSON.stringify({ result: "Success" }),
  };
};