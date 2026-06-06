// This Lambda function receives form data from the frontend, constructs an email, and sends it using AWS SES.

import { SESClient, SendEmailCommand } from "@aws-sdk/client-ses";

const ses = new SESClient({ region: "us-east-1" });

const RECEIVER = process.env.RECEIVER_EMAIL;
const SENDER = process.env.SENDER_EMAIL;

export const handler = async (event) => {
  console.log("Received event:", event);

  const params = {
    Destination: { ToAddresses: [RECEIVER] },
    Message: {
      Body: {
        Text: {
          Data: `Full Name: ${event.name}
Phone: ${event.phone}
Email: ${event.email}
Message: ${event.message}`,
          Charset: "UTF-8",
        },
      },
      Subject: { Data: `Website Query Form: ${event.name}`, Charset: "UTF-8" },
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