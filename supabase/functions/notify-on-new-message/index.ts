// supabase/functions/notify-on-new-message/index.ts

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.0.0";
import { create, getNumericDate } from "https://deno.land/x/djwt@v2.2/mod.ts";

// --- START OF NEW v1 AUTH LOGIC ---

// Helper function to get a short-lived OAuth2 access token
async function getAccessToken(serviceAccountJson: string) {
  const serviceAccount = JSON.parse(serviceAccountJson);
  const jwt = await create(
    { alg: "RS256", typ: "JWT" },
    {
      scope: "https://www.googleapis.com/auth/cloud-platform",
      aud: "https://oauth2.googleapis.com/token",
      iss: serviceAccount.client_email,
      iat: getNumericDate(0),
      exp: getNumericDate(3600), // Token expires in 1 hour
    },
    serviceAccount.private_key
  );

  const response = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: jwt,
    }),
  });

  const tokens = await response.json();
  if (!response.ok) {
    throw new Error(`Failed to get access token: ${JSON.stringify(tokens)}`);
  }
  return tokens.access_token;
}
// --- END OF NEW v1 AUTH LOGIC ---


interface Message {
  id: string;
  chat_id: string;
  sender_id: string;
  text?: string;
  attachment_type?: 'image' | 'video' | 'file';
}

serve(async (req) => {
  try {
    const serviceAccountJson = Deno.env.get("FCM_SERVICE_ACCOUNT_JSON");
    if (!serviceAccountJson) {
      throw new Error("FCM_SERVICE_ACCOUNT_JSON is not set in Supabase secrets.");
    }
    const serviceAccount = JSON.parse(serviceAccountJson);
    const projectId = serviceAccount.project_id;
    const fcmV1Endpoint = `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`;
    
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );

    const { record: newMessage } = await req.json() as { record: Message };

    // 1. Get the chat details to find the recipient
    const { data: chatData, error: chatError } = await supabase
      .from("chats")
      .select("renter_id, landlord_id")
      .eq("id", newMessage.chat_id)
      .single();

    if (chatError) throw chatError;
    
    const recipientId = chatData.renter_id === newMessage.sender_id
      ? chatData.landlord_id
      : chatData.renter_id;
      
    if (!recipientId) {
      return new Response(JSON.stringify({ message: "No recipient." }), { status: 200 });
    }

    // 2. Get sender's name for the notification
    const { data: senderProfile } = await supabase
      .from("profiles")
      .select("user_name")
      .eq("id", newMessage.sender_id)
      .single();
    const senderName = senderProfile?.user_name || "New Message";

    // 3. Get recipient's FCM tokens
    const { data: tokens, error: tokensError } = await supabase
      .from("fcm_tokens")
      .select("token")
      .eq("user_id", recipientId);

    if (tokensError) throw tokensError;
    if (!tokens || tokens.length === 0) {
      return new Response(JSON.stringify({ message: "No tokens found." }), { status: 200 });
    }
    
    // Determine the message body
    let messageBody = "You received a new message.";
    if (newMessage.text) {
      messageBody = newMessage.text;
    } else if (newMessage.attachment_type) {
      const type = newMessage.attachment_type.charAt(0).toUpperCase() + newMessage.attachment_type.slice(1);
      messageBody = `Sent you a new ${type}.`;
    }

    // 4. Get the OAuth2 access token
    const accessToken = await getAccessToken(serviceAccountJson);
    
    // 5. Send notifications for each token
    for (const record of tokens) {
      const fcmToken = record.token;
      
      const notificationPayload = {
        message: {
          token: fcmToken,
          notification: {
            title: senderName,
            body: messageBody,
          },
          data: {
            chat_id: newMessage.chat_id,
          },
        },
      };

      const response = await fetch(fcmV1Endpoint, {
        method: "POST",
        headers: {
          "Authorization": `Bearer ${accessToken}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify(notificationPayload),
      });

      if (!response.ok) {
        const errorBody = await response.text();
        console.error(`FCM request for token ${fcmToken} failed: ${response.statusText}`, errorBody);
      } else {
        console.log(`Successfully sent notification to device ${fcmToken}.`);
      }
    }

    return new Response(JSON.stringify({ success: true }), {
      headers: { "Content-Type": "application/json" },
    });

  } catch (err) {
    console.error("Error sending push notification:", err);
    return new Response(String(err?.message ?? err), { status: 500 });
  }
});