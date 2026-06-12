-- ============================================================
-- Migration 025 — Create Trigger for Chat Push Notifications
-- ============================================================
-- Note: This trigger calls the Supabase Edge Function to send FCM push notifications.
-- Since the Project URL and Service Role Key are environment-specific,
-- you can EITHER:
--
-- METHOD A: Create it via the Supabase Dashboard UI (RECOMMENDED):
--   1. Go to Supabase Dashboard -> Database -> Webhooks.
--   2. Click "Create Webhook".
--   3. Name: "send-chat-notification".
--   4. Table: "chat_messages", Event: "INSERT".
--   5. Type: "Supabase Edge Function".
--   6. Select the Edge Function: "send-chat-notification".
--   7. Click "Save".
--
-- METHOD B: Run the SQL below in the SQL Editor after replacing:
--   - YOUR_PROJECT_REF with your actual Supabase project reference ID.
--   - YOUR_SERVICE_ROLE_KEY with your actual Supabase Service Role Key (secret).
-- ============================================================

-- Enable the pg_net extension if not enabled
CREATE EXTENSION IF NOT EXISTS pg_net;

CREATE OR REPLACE FUNCTION public.send_chat_message_notification_trigger()
RETURNS TRIGGER AS $$
BEGIN
  -- Perform an HTTP POST to the Supabase Edge Function
  -- Replace <YOUR_PROJECT_REF> and <YOUR_SERVICE_ROLE_KEY> if running manually.
  -- Otherwise, configure via Supabase Dashboard UI Webhooks.
  PERFORM net.http_post(
    url := 'https://YOUR_PROJECT_REF.supabase.co/functions/v1/send-chat-notification',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer YOUR_SERVICE_ROLE_KEY'
    ),
    body := jsonb_build_object(
      'record', row_to_json(NEW)
    ),
    timeout_milliseconds := 5000
  );
  RETURN NEW;
EXCEPTION WHEN OTHERS THEN
  -- Never block chat message insert if notification fails
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger name: tr_send_chat_message_notification
-- DROP TRIGGER IF EXISTS tr_send_chat_message_notification ON public.chat_messages;
-- CREATE TRIGGER tr_send_chat_message_notification
--   AFTER INSERT ON public.chat_messages
--   FOR EACH ROW
--   EXECUTE FUNCTION public.send_chat_message_notification_trigger();
