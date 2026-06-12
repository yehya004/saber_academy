import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "npm:@supabase/supabase-js@2.39.8";
import { GoogleAuth } from "npm:google-auth-library@9.6.0";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (req: Request) => {
  // Handle CORS
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const payload = await req.json();
    const record = payload.record;

    if (!record) {
      return new Response(JSON.stringify({ error: "No record provided" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const { sender_id: senderId, receiver_id: receiverId, message_text: messageText } = record;

    if (!senderId || !receiverId) {
      return new Response(JSON.stringify({ error: "Missing sender or receiver ID" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Initialize Supabase client
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseServiceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(supabaseUrl, supabaseServiceRoleKey);

    // 1. Fetch receiver's FCM token
    const { data: receiverProfile, error: receiverError } = await supabase
      .from("profiles")
      .select("fcm_token, language_preference")
      .eq("id", receiverId)
      .single();

    if (receiverError || !receiverProfile || !receiverProfile.fcm_token) {
      console.log(`No FCM token found for receiver: ${receiverId}`);
      return new Response(JSON.stringify({ message: "Receiver has no FCM token saved" }), {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // 2. Fetch sender's name
    const { data: senderProfile } = await supabase
      .from("profiles")
      .select("full_name")
      .eq("id", senderId)
      .single();

    const senderName = senderProfile?.full_name || "مستخدم";
    const fcmToken = receiverProfile.fcm_token;
    const lang = receiverProfile.language_preference || "ar";

    // 3. Define titles/bodies based on language preference
    let notificationTitle = "رسالة جديدة";
    let notificationBody = messageText || "أرسل لك مرفقاً";

    if (lang === "tr") {
      notificationTitle = `${senderName} size bir mesaj gönderdi`;
    } else if (lang === "en") {
      notificationTitle = `New message from ${senderName}`;
    } else {
      notificationTitle = `رسالة جديدة من ${senderName}`;
    }

    // 4. Authenticate with Google FCM v1 using Service Account
    const serviceAccountJson = Deno.env.get("FIREBASE_SERVICE_ACCOUNT");
    if (!serviceAccountJson) {
      throw new Error("Missing FIREBASE_SERVICE_ACCOUNT environment variable on Supabase.");
    }

    const serviceAccount = JSON.parse(serviceAccountJson);
    const projectId = serviceAccount.project_id;

    if (!projectId) {
      throw new Error("Invalid FIREBASE_SERVICE_ACCOUNT: Missing project_id");
    }

    const auth = new GoogleAuth({
      credentials: serviceAccount,
      scopes: ["https://www.googleapis.com/auth/firebase.messaging"],
    });

    const client = await auth.getClient();
    const tokenResponse = await client.getAccessToken();
    const accessToken = tokenResponse.token;

    if (!accessToken) {
      throw new Error("Failed to obtain OAuth2 access token for Firebase FCM");
    }

    // 5. Send Notification via FCM v1 API
    const fcmUrl = `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`;
    const fcmPayload = {
      message: {
        token: fcmToken,
        notification: {
          title: notificationTitle,
          body: notificationBody,
        },
        android: {
          priority: "high",
          notification: {
            sound: "default",
            click_action: "FLUTTER_NOTIFICATION_CLICK",
            channel_id: "saber_academy_notifications_v3",
          },
        },
        apns: {
          payload: {
            aps: {
              sound: "default",
              badge: 1,
            },
          },
        },
        data: {
          click_action: "FLUTTER_NOTIFICATION_CLICK",
          senderId: senderId,
          receiverId: receiverId,
          senderName: senderName,
        },
      },
    };

    const response = await fetch(fcmUrl, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${accessToken}`,
      },
      body: JSON.stringify(fcmPayload),
    });

    const result = await response.json();

    if (!response.ok) {
      throw new Error(`FCM API responded with status ${response.status}: ${JSON.stringify(result)}`);
    }

    console.log(`Notification sent successfully to ${receiverId}`);
    return new Response(JSON.stringify({ success: true, result }), {
      status: 200,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (error) {
    console.error("Error sending notification:", error);
    const errorMessage = error instanceof Error ? error.message : String(error);
    return new Response(JSON.stringify({ error: errorMessage }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
