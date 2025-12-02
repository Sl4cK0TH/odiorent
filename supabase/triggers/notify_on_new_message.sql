--  Database trigger to call our Edge Function when a new message is inserted.

-- 1. Define the function that will be called by the trigger.
CREATE OR REPLACE FUNCTION trigger_notify_on_new_message()
RETURNS TRIGGER AS $$
DECLARE
  request_id bigint;
BEGIN
  -- Asynchronously invoke the Edge Function using net.http_post
  SELECT net.http_post(
    url:='https://oxxjpcjusuemhdjpyssy.supabase.co/functions/v1/notify-on-new-message',
    headers:=jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im94eGpwY2p1c3VlbWhkanB5c3N5Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MTU1MTY1NywiZXhwIjoyMDc3MTI3NjU3fQ.TClQ8gtw9ETtplpMdyQbsaVDF5UULIX8CCCkk6TWg4U'
    ),
    body:=jsonb_build_object('record', to_jsonb(NEW))
  ) INTO request_id;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. Create the trigger that fires after a new row is inserted into 'messages'.
DROP TRIGGER IF EXISTS on_new_message_notify ON public.messages;
CREATE TRIGGER on_new_message_notify
AFTER INSERT ON public.messages
FOR EACH ROW
EXECUTE FUNCTION trigger_notify_on_new_message();
