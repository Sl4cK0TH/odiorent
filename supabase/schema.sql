


SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;


COMMENT ON SCHEMA "public" IS 'standard public schema';



CREATE EXTENSION IF NOT EXISTS "pg_graphql" WITH SCHEMA "graphql";






CREATE EXTENSION IF NOT EXISTS "pg_stat_statements" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "pgcrypto" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "supabase_vault" WITH SCHEMA "vault";






CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA "extensions";






CREATE OR REPLACE FUNCTION "public"."handle_new_user"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
BEGIN
  -- Insert into public.profiles, now with all fields
  INSERT INTO public.profiles (
    id, email, 
    last_name, first_name, middle_name, user_name, 
    phone_number, -- ADDED
    role
  )
  VALUES (
    new.id, 
    new.email,
    new.raw_user_meta_data ->> 'last_name',
    new.raw_user_meta_data ->> 'first_name',
    new.raw_user_meta_data ->> 'middle_name',
    new.raw_user_meta_data ->> 'user_name',
    new.raw_user_meta_data ->> 'phone_number', -- ADDED
    new.raw_user_meta_data ->> 'role'
  );
  RETURN new;
END;
$$;


ALTER FUNCTION "public"."handle_new_user"() OWNER TO "postgres";

SET default_tablespace = '';

SET default_table_access_method = "heap";


CREATE TABLE IF NOT EXISTS "public"."chat_participants" (
    "chat_id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" DEFAULT "gen_random_uuid"()
);


ALTER TABLE "public"."chat_participants" OWNER TO "postgres";


COMMENT ON TABLE "public"."chat_participants" IS 'We need two tables for chat. One holds the chat "room," and the other links users to that room.';



CREATE TABLE IF NOT EXISTS "public"."chats" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "last_message" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "last_message_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."chats" OWNER TO "postgres";


COMMENT ON TABLE "public"."chats" IS 'We need two tables for chat. One holds the chat "room," and the other links users to that room.';



CREATE TABLE IF NOT EXISTS "public"."messages" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "chat_id" "uuid",
    "sender_id" "uuid",
    "text" "text",
    "sent_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."messages" OWNER TO "postgres";


COMMENT ON TABLE "public"."messages" IS 'The table to hold the actual messages for each chat.';



CREATE TABLE IF NOT EXISTS "public"."notifications" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "recipient_id" "uuid" NOT NULL,
    "title" "text" NOT NULL,
    "body" "text" NOT NULL,
    "link" "text",
    "is_read" boolean DEFAULT false NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."notifications" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."profiles" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "email" character varying,
    "role" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "last_name" "text",
    "first_name" "text",
    "middle_name" "text",
    "user_name" "text",
    "phone_number" "text",
    "profile_picture_url" "text"
);


ALTER TABLE "public"."profiles" OWNER TO "postgres";


COMMENT ON TABLE "public"."profiles" IS 'This table will store user data (like their role) and is linked to the built-in auth.users table.';



CREATE TABLE IF NOT EXISTS "public"."properties" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "landlord_id" "uuid",
    "name" "text",
    "address" character varying,
    "description" "text",
    "price" numeric,
    "rooms" bigint,
    "beds" bigint,
    "image_urls" "text"[],
    "status" "text" DEFAULT '''pending'''::"text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "approved_at" timestamp with time zone
);


ALTER TABLE "public"."properties" OWNER TO "postgres";


COMMENT ON TABLE "public"."properties" IS 'This table will store the rental listings.';



ALTER TABLE ONLY "public"."chats"
    ADD CONSTRAINT "chats_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."messages"
    ADD CONSTRAINT "messages_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."notifications"
    ADD CONSTRAINT "notifications_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profiles_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."properties"
    ADD CONSTRAINT "properties_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."chat_participants"
    ADD CONSTRAINT "chat_participants_chat_id_fkey" FOREIGN KEY ("chat_id") REFERENCES "public"."chats"("id");



ALTER TABLE ONLY "public"."chat_participants"
    ADD CONSTRAINT "chat_participants_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("id");



ALTER TABLE ONLY "public"."messages"
    ADD CONSTRAINT "messages_chat_id_fkey" FOREIGN KEY ("chat_id") REFERENCES "public"."chats"("id");



ALTER TABLE ONLY "public"."messages"
    ADD CONSTRAINT "messages_sender_id_fkey" FOREIGN KEY ("sender_id") REFERENCES "public"."profiles"("id");



ALTER TABLE ONLY "public"."notifications"
    ADD CONSTRAINT "notifications_recipient_id_fkey" FOREIGN KEY ("recipient_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profiles_id_fkey" FOREIGN KEY ("id") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."properties"
    ADD CONSTRAINT "properties_landlord_id_fkey" FOREIGN KEY ("landlord_id") REFERENCES "public"."profiles"("id");



CREATE POLICY "Admins can update any property" ON "public"."properties" FOR UPDATE TO "authenticated" USING ((( SELECT "profiles"."role"
   FROM "public"."profiles"
  WHERE ("profiles"."id" = ( SELECT "auth"."uid"() AS "uid"))) = 'admin'::"text")) WITH CHECK ((( SELECT "profiles"."role"
   FROM "public"."profiles"
  WHERE ("profiles"."id" = ( SELECT "auth"."uid"() AS "uid"))) = 'admin'::"text"));



CREATE POLICY "Admins can view all properties" ON "public"."properties" FOR SELECT TO "authenticated" USING ((( SELECT "profiles"."role"
   FROM "public"."profiles"
  WHERE ("profiles"."id" = "auth"."uid"())) = 'admin'::"text"));



CREATE POLICY "Allow anon select on profiles" ON "public"."profiles" FOR SELECT TO "anon" USING (true);



CREATE POLICY "Allow read/write if user is a participant" ON "public"."chat_participants" TO "authenticated" USING (("auth"."uid"() IN ( SELECT "chat_participants_1"."user_id"
   FROM "public"."chat_participants" "chat_participants_1"
  WHERE ("chat_participants_1"."chat_id" = "chat_participants_1"."chat_id")))) WITH CHECK (("auth"."uid"() IN ( SELECT "chat_participants_1"."user_id"
   FROM "public"."chat_participants" "chat_participants_1"
  WHERE ("chat_participants_1"."chat_id" = "chat_participants_1"."chat_id"))));



CREATE POLICY "Allow read/write if user is a participant" ON "public"."chats" TO "authenticated" USING (("auth"."uid"() IN ( SELECT "chat_participants"."user_id"
   FROM "public"."chat_participants"
  WHERE ("chat_participants"."chat_id" = "chats"."id")))) WITH CHECK (("auth"."uid"() IN ( SELECT "chat_participants"."user_id"
   FROM "public"."chat_participants"
  WHERE ("chat_participants"."chat_id" = "chats"."id"))));



CREATE POLICY "Allow read/write if user is a participant" ON "public"."messages" TO "authenticated" USING (("auth"."uid"() IN ( SELECT "chat_participants"."user_id"
   FROM "public"."chat_participants"
  WHERE ("chat_participants"."chat_id" = "messages"."chat_id")))) WITH CHECK (("auth"."uid"() IN ( SELECT "chat_participants"."user_id"
   FROM "public"."chat_participants"
  WHERE ("chat_participants"."chat_id" = "messages"."chat_id"))));



CREATE POLICY "Landlords can create properties" ON "public"."properties" FOR INSERT TO "authenticated" WITH CHECK ((( SELECT "profiles"."role"
   FROM "public"."profiles"
  WHERE ("profiles"."id" = ( SELECT "auth"."uid"() AS "uid"))) = 'landlord'::"text"));



CREATE POLICY "Landlords can delete their own properties" ON "public"."properties" FOR DELETE TO "authenticated" USING (("auth"."uid"() = "landlord_id"));



CREATE POLICY "Landlords can insert their own properties" ON "public"."properties" FOR INSERT TO "authenticated" WITH CHECK (("auth"."uid"() = "landlord_id"));



CREATE POLICY "Landlords can read their own properties" ON "public"."properties" FOR SELECT TO "authenticated" USING (("auth"."uid"() = "landlord_id"));



CREATE POLICY "Landlords can update their own properties" ON "public"."properties" FOR UPDATE TO "authenticated" USING (("auth"."uid"() = "landlord_id")) WITH CHECK (("auth"."uid"() = "landlord_id"));



CREATE POLICY "Users can view their own notifications" ON "public"."notifications" FOR SELECT TO "authenticated" USING (("recipient_id" = "auth"."uid"()));



CREATE POLICY "allow_public_read_approved_properties" ON "public"."properties" FOR SELECT USING (("status" = 'approved'::"text"));



ALTER TABLE "public"."chat_participants" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."chats" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."messages" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."notifications" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."profiles" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "profiles_select_own_profile" ON "public"."profiles" FOR SELECT TO "authenticated" USING ((( SELECT "auth"."uid"() AS "uid") = "id"));



CREATE POLICY "profiles_update_own_profile" ON "public"."profiles" FOR UPDATE TO "authenticated" USING ((( SELECT "auth"."uid"() AS "uid") = "id")) WITH CHECK ((( SELECT "auth"."uid"() AS "uid") = "id"));



ALTER TABLE "public"."properties" ENABLE ROW LEVEL SECURITY;




ALTER PUBLICATION "supabase_realtime" OWNER TO "postgres";






GRANT USAGE ON SCHEMA "public" TO "postgres";
GRANT USAGE ON SCHEMA "public" TO "anon";
GRANT USAGE ON SCHEMA "public" TO "authenticated";
GRANT USAGE ON SCHEMA "public" TO "service_role";

























































































































































GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "anon";
GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "service_role";


















GRANT ALL ON TABLE "public"."chat_participants" TO "anon";
GRANT ALL ON TABLE "public"."chat_participants" TO "authenticated";
GRANT ALL ON TABLE "public"."chat_participants" TO "service_role";



GRANT ALL ON TABLE "public"."chats" TO "anon";
GRANT ALL ON TABLE "public"."chats" TO "authenticated";
GRANT ALL ON TABLE "public"."chats" TO "service_role";



GRANT ALL ON TABLE "public"."messages" TO "anon";
GRANT ALL ON TABLE "public"."messages" TO "authenticated";
GRANT ALL ON TABLE "public"."messages" TO "service_role";



GRANT ALL ON TABLE "public"."notifications" TO "anon";
GRANT ALL ON TABLE "public"."notifications" TO "authenticated";
GRANT ALL ON TABLE "public"."notifications" TO "service_role";



GRANT ALL ON TABLE "public"."profiles" TO "anon";
GRANT ALL ON TABLE "public"."profiles" TO "authenticated";
GRANT ALL ON TABLE "public"."profiles" TO "service_role";



GRANT ALL ON TABLE "public"."properties" TO "anon";
GRANT ALL ON TABLE "public"."properties" TO "authenticated";
GRANT ALL ON TABLE "public"."properties" TO "service_role";









ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "service_role";































