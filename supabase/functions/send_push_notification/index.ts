import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { importPKCS8, SignJWT } from "npm:jose@5";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

interface ServiceAccount {
  project_id: string;
  private_key: string;
  client_email: string;
}

interface WebhookRecord {
  user_id: string;
  id: string;
  status: string;
  [key: string]: any;
}

interface NotificationPayload {
  user_id?: string;
  title?: string;
  body?: string;
  data?: Record<string, string> | any;
  record?: WebhookRecord;
}

// @ts-ignore: Deno namespace
Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  console.log("Function invoked!");

  try {
    const json = await req.json();
    console.log("Payload received:", JSON.stringify(json));

    let { user_id, title, body, data } = json as NotificationPayload;

    // Handle Supabase Database Webhook payload
    if (!user_id && json.record && json.record.user_id) {
      console.log("Processing Webhook Payload...");
      const record = json.record;
      user_id = record.user_id;
      title = "Order Updated";
      body = `Your order #${record.id} status is now ${record.status}`;

      const status = record.status?.toLowerCase();
      console.log(`Order ID: ${record.id}, Status: ${status}`);

      if (status === "shipped") {
        title = "Paket Dikirim!";
        body = `Pesanan #${record.id} sedang dalam perjalanan.`;
      } else if (status === "completed") {
        title = "Pesanan Selesai!";
        body = `Pesanan #${record.id} telah selesai. Terima kasih telah berbelanja!`;
      }

      data = {
        type: "order_update",
        status: record.status,
        order_id: record.id,
        click_action: "FLUTTER_NOTIFICATION_CLICK",
      };
    }

    if (!user_id) {
      console.error("Missing user_id");
      throw new Error("Missing user_id");
    }

    // 1. Get Service Account from Env
    // @ts-ignore: Deno namespace
    const serviceAccountStr = Deno.env.get("FCM_SERVICE_ACCOUNT");
    if (!serviceAccountStr) {
      console.error("Missing FCM_SERVICE_ACCOUNT secret");
      throw new Error("Missing FCM_SERVICE_ACCOUNT secret");
    }
    const serviceAccount: ServiceAccount = JSON.parse(serviceAccountStr);

    // 2. Initialize Supabase Client
    const supabaseClient = createClient(
      // @ts-ignore: Deno namespace
      Deno.env.get("SUPABASE_URL") ?? "",
      // @ts-ignore: Deno namespace
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
    );

    // 3. Get User Tokens from DB
    console.log(`Fetching devices for user: ${user_id}`);
    const { data: devices, error: dbError } = await supabaseClient
      .from("user_devices")
      .select("fcm_token")
      .eq("user_id", user_id!);

    if (dbError) {
      console.error("DB Error:", dbError);
      throw dbError;
    }
    if (!devices || devices.length === 0) {
      console.log("No devices found for user.");
      return new Response(
        JSON.stringify({ message: "No devices found for user" }),
        {
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    console.log(`Found ${devices.length} devices. Generating Access Token...`);

    // 4. Generate Access Token (JWT -> OAuth2)
    const accessToken = await getAccessToken(serviceAccount);
    console.log("Access Token generated.");

    // 5. Send Notifications
    const results = await Promise.all(
      devices.map(async (device: { fcm_token: string }) => {
        try {
          console.log(
            `Sending to token: ${device.fcm_token.substring(0, 10)}...`
          );
          const res = await fetch(
            `https://fcm.googleapis.com/v1/projects/${serviceAccount.project_id}/messages:send`,
            {
              method: "POST",
              headers: {
                "Content-Type": "application/json",
                Authorization: `Bearer ${accessToken}`,
              },
              body: JSON.stringify({
                message: {
                  token: device.fcm_token,
                  notification: {
                    title: title,
                    body: body,
                  },
                  data: data || {}, // data must be map of strings
                },
              }),
            }
          );

          const json = await res.json();
          console.log("FCM Response:", JSON.stringify(json));

          if (!res.ok) {
            // If token is invalid (UNREGISTERED), remove it from DB
            if (json.error?.details?.[0]?.errorCode === "UNREGISTERED") {
              console.log("Removing invalid token...");
              await supabaseClient
                .from("user_devices")
                .delete()
                .eq("fcm_token", device.fcm_token);
            }
            return { success: false, error: json };
          }

          return { success: true, result: json };
        } catch (e) {
          console.error("FCM Send Error:", e);
          return { success: false, error: (e as Error).toString() };
        }
      })
    );

    console.log("All notifications processed.");
    return new Response(JSON.stringify(results), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (error) {
    console.error("Global Error:", error);
    return new Response(JSON.stringify({ error: (error as Error).message }), {
      status: 400,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});

// Helper to get Google OAuth2 Access Token using Service Account
async function getAccessToken(serviceAccount: ServiceAccount) {
  const algorithm = "RS256";
  const pkcs8 = await importPKCS8(serviceAccount.private_key, algorithm);

  const jwt = await new SignJWT({
    iss: serviceAccount.client_email,
    sub: serviceAccount.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
  })
    .setProtectedHeader({ alg: algorithm, typ: "JWT" })
    .setIssuedAt()
    .setExpirationTime("1h")
    .sign(pkcs8);

  // Exchange JWT for Access Token
  const res = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${jwt}`,
  });

  const json = await res.json();
  return json.access_token;
}
