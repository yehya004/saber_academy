-- Re-create the function
CREATE OR REPLACE FUNCTION public.send_chat_message_notification_trigger()
RETURNS TRIGGER AS $$
BEGIN
  PERFORM net.http_post(
    url := 'https://hgbefqwtjkpowktumkgz.supabase.co/functions/v1/send-chat-notification',
    headers := '{"Content-Type": "application/json"}'::jsonb,
    body := jsonb_build_object(
      'record', row_to_json(NEW)
    ),
    timeout_milliseconds := 5000
  );
  RETURN NEW;
EXCEPTION WHEN OTHERS THEN
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Re-create the trigger
DROP TRIGGER IF EXISTS tr_send_chat_message_notification ON public.chat_messages;
CREATE TRIGGER tr_send_chat_message_notification
  AFTER INSERT ON public.chat_messages
  FOR EACH ROW
  EXECUTE FUNCTION public.send_chat_message_notification_trigger();
