--
-- Optimized Supabase Schema for Odiorent (v2 - With Chat Features)
--
-- Optimizations & Features:
-- 1. Adds Indexes for faster queries.
-- 2. Uses ENUM types for 'role', 'status', and attachment types.
-- 3. Enables 'pg_trgm' for efficient text search.
-- 4. Refactored RLS policies with a helper function.
-- 5. Adds schema support for Read Receipts, Multimedia Messages,
--    Push Notifications, and Online Presence.
--

-- Set up schema and basic settings
SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', 'public', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

-- Drop existing objects to re-create them cleanly
DROP VIEW IF EXISTS "public"."properties_with_avg_rating" CASCADE;
DROP FUNCTION IF EXISTS "public"."handle_new_user"() CASCADE;
DROP FUNCTION IF EXISTS "public"."is_admin"() CASCADE;
DROP TABLE IF EXISTS "public"."messages" CASCADE;
DROP TABLE IF EXISTS "public"."property_ratings" CASCADE;
DROP TABLE IF EXISTS "public"."notifications" CASCADE;
DROP TABLE IF EXISTS "public"."fcm_tokens" CASCADE;
DROP TABLE IF EXISTS "public"."chats" CASCADE;
DROP TABLE IF EXISTS "public"."properties" CASCADE;
DROP TABLE IF EXISTS "public"."profiles" CASCADE;
DROP TYPE IF EXISTS "public"."user_role" CASCADE;
DROP TYPE IF EXISTS "public"."property_status" CASCADE;
DROP TYPE IF EXISTS "public"."message_attachment_type" CASCADE;

-- Enable extensions
CREATE EXTENSION IF NOT EXISTS "pg_trgm" WITH SCHEMA "public";
CREATE EXTENSION IF NOT EXISTS "pg_net" WITH SCHEMA "extensions";

-- =================================================================
--  1. TYPE DEFINITIONS
-- =================================================================

CREATE TYPE "public"."user_role" AS ENUM ('renter', 'landlord', 'admin');
CREATE TYPE "public"."property_status" AS ENUM ('pending', 'approved', 'rejected');
CREATE TYPE "public"."message_attachment_type" AS ENUM ('image', 'video', 'file');

-- =================================================================
--  2. TABLE CREATION
-- =================================================================

-- Profiles Table
CREATE TABLE "public"."profiles" (
    "id" "uuid" PRIMARY KEY NOT NULL REFERENCES "auth"."users"("id") ON DELETE CASCADE,
    "email" "text" UNIQUE,
    "role" "public"."user_role" DEFAULT 'renter',
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "last_name" "text",
    "first_name" "text",
    "middle_name" "text",
    "user_name" "text",
    "phone_number" "text",
    "profile_picture_url" "text",
    "last_seen" timestamp with time zone -- For online presence
);
COMMENT ON TABLE "public"."profiles" IS 'Stores user profile data, linked to auth.users.';

-- Properties Table (No changes from before)
CREATE TABLE "public"."properties" (
    "id" "uuid" PRIMARY KEY DEFAULT "gen_random_uuid"(),
    "landlord_id" "uuid" NOT NULL REFERENCES "public"."profiles"("id") ON DELETE CASCADE,
    "name" "text", "address" "text", "description" "text", "price" numeric,
    "rooms" integer, "beds" integer, "image_urls" "text"[],
    "status" "public"."property_status" DEFAULT 'pending' NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "approved_at" timestamp with time zone
);
COMMENT ON TABLE "public"."properties" IS 'Stores rental property listings.';

-- Property Ratings Table (No changes from before)
CREATE TABLE "public"."property_ratings" (
    "id" "uuid" PRIMARY KEY DEFAULT "gen_random_uuid"(),
    "property_id" "uuid" NOT NULL REFERENCES "public"."properties"("id") ON DELETE CASCADE,
    "user_id" "uuid" NOT NULL REFERENCES "public"."profiles"("id") ON DELETE CASCADE,
    "rating" smallint NOT NULL CHECK (("rating" >= 1) AND ("rating" <= 5)),
    "comment" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    UNIQUE ("user_id", "property_id")
);
COMMENT ON TABLE "public"."property_ratings" IS 'Stores user ratings for properties.';

-- Chats Table (No changes from before)
CREATE TABLE "public"."chats" (
    "id" "uuid" PRIMARY KEY DEFAULT "gen_random_uuid"(),
    "property_id" "uuid" REFERENCES "public"."properties"("id") ON DELETE SET NULL,
    "renter_id" "uuid" REFERENCES "public"."profiles"("id") ON DELETE SET NULL,
    "landlord_id" "uuid" REFERENCES "public"."profiles"("id") ON DELETE SET NULL,
    "last_message" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "last_message_at" timestamp with time zone DEFAULT "now"()
);
COMMENT ON TABLE "public"."chats" IS 'Represents a chat conversation.';

-- Messages Table (UPDATED)
CREATE TABLE "public"."messages" (
    "id" "uuid" PRIMARY KEY DEFAULT "gen_random_uuid"(),
    "chat_id" "uuid" NOT NULL REFERENCES "public"."chats"("id") ON DELETE CASCADE,
    "sender_id" "uuid" NOT NULL REFERENCES "public"."profiles"("id") ON DELETE CASCADE,
    "text" "text", -- Now nullable
    "sent_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "read_at" timestamp with time zone, -- For read receipts
    "attachment_url" "text", -- For multimedia support
    "attachment_type" "public"."message_attachment_type", -- For multimedia support
    CONSTRAINT "message_has_content" CHECK (("text" IS NOT NULL) OR ("attachment_url" IS NOT NULL))
);
COMMENT ON TABLE "public"."messages" IS 'Stores individual chat messages with support for text and attachments.';

-- Notifications Table (No changes from before)
CREATE TABLE "public"."notifications" (
    "id" "uuid" PRIMARY KEY DEFAULT "gen_random_uuid"(),
    "recipient_id" "uuid" NOT NULL REFERENCES "public"."profiles"("id") ON DELETE CASCADE,
    "title" "text" NOT NULL, "body" "text" NOT NULL, "link" "text",
    "is_read" boolean DEFAULT false NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);
COMMENT ON TABLE "public"."notifications" IS 'Stores user notifications.';

-- FCM Tokens Table (NEW)
CREATE TABLE "public"."fcm_tokens" (
    "id" "uuid" PRIMARY KEY DEFAULT "gen_random_uuid"(),
    "user_id" "uuid" NOT NULL REFERENCES "public"."profiles"("id") ON DELETE CASCADE,
    "token" "text" NOT NULL UNIQUE,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);
COMMENT ON TABLE "public"."fcm_tokens" IS 'Stores FCM device tokens for push notifications.';

-- =================================================================
--  3. INDEXES
-- =================================================================
-- Existing indexes...
CREATE INDEX "idx_profiles_role" ON "public"."profiles"("role");
CREATE INDEX "idx_properties_landlord_id" ON "public"."properties"("landlord_id");
CREATE INDEX "idx_properties_status" ON "public"."properties"("status");
CREATE INDEX "idx_properties_search" ON "public"."properties" USING GIN ("name" "public"."gin_trgm_ops", "address" "public"."gin_trgm_ops", "description" "public"."gin_trgm_ops");
CREATE INDEX "idx_property_ratings_property_id" ON "public"."property_ratings"("property_id");
CREATE INDEX "idx_property_ratings_user_id" ON "public"."property_ratings"("user_id");
CREATE INDEX "idx_chats_renter_id" ON "public"."chats"("renter_id");
CREATE INDEX "idx_chats_landlord_id" ON "public"."chats"("landlord_id");
CREATE INDEX "idx_chats_property_id" ON "public"."chats"("property_id");
CREATE INDEX "idx_messages_chat_id" ON "public"."messages"("chat_id");
CREATE INDEX "idx_messages_sender_id" ON "public"."messages"("sender_id");
CREATE INDEX "idx_notifications_recipient_id" ON "public"."notifications"("recipient_id");
-- New indexes
CREATE INDEX "idx_messages_read_at" ON "public"."messages" ("read_at");
CREATE INDEX "idx_fcm_tokens_user_id" ON "public"."fcm_tokens" ("user_id");

-- =================================================================
--  4. VIEWS & FUNCTIONS
-- =================================================================
-- These are unchanged from the previous version.
CREATE OR REPLACE VIEW "public"."properties_with_avg_rating" AS
SELECT p.id, p.landlord_id, p.name, p.address, p.description, p.price, p.rooms, p.beds,
    p.image_urls, p.status, p.created_at, p.approved_at,
    COALESCE(avg_ratings.average_rating, 0) AS average_rating,
    COALESCE(avg_ratings.rating_count, 0) AS rating_count,
    prof.user_name, prof.first_name, prof.last_name, prof.email, prof.phone_number, prof.profile_picture_url
FROM public.properties AS p
LEFT JOIN (
    SELECT pr.property_id, avg(pr.rating) AS average_rating, count(pr.id) AS rating_count
    FROM public.property_ratings AS pr GROUP BY pr.property_id
) AS avg_ratings ON p.id = avg_ratings.property_id
LEFT JOIN public.profiles AS prof ON p.landlord_id = prof.id;

CREATE OR REPLACE FUNCTION "public"."handle_new_user"() RETURNS "trigger" AS $$
BEGIN
  INSERT INTO public.profiles (id, email, role, first_name, last_name, user_name, phone_number)
  VALUES ( new.id, new.email, (new.raw_user_meta_data->>'role')::public.user_role,
    new.raw_user_meta_data->>'first_name', new.raw_user_meta_data->>'last_name',
    new.raw_user_meta_data->>'user_name', new.raw_user_meta_data->>'phone_number'
  );
  RETURN new;
END;
$$ LANGUAGE "plpgsql" SECURITY DEFINER;

CREATE TRIGGER "on_auth_user_created"
AFTER INSERT ON "auth"."users" FOR EACH ROW EXECUTE PROCEDURE "public"."handle_new_user"();

CREATE OR REPLACE FUNCTION "public"."is_admin"() RETURNS "bool" AS $$
BEGIN
  RETURN EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin');
END;
$$ LANGUAGE "plpgsql" SECURITY DEFINER;

CREATE OR REPLACE FUNCTION "public"."search_properties"("search_term" "text")
RETURNS SETOF "public"."properties_with_avg_rating" AS $$
BEGIN
  RETURN QUERY SELECT * FROM public.properties_with_avg_rating
  WHERE status = 'approved' AND ( name ILIKE '%' || search_term || '%' OR address ILIKE '%' || search_term || '%'
      OR description ILIKE '%' || search_term || '%' OR user_name ILIKE '%' || search_term || '%'
      OR first_name ILIKE '%' || search_term || '%' OR last_name ILIKE '%' || search_term || '%' )
  ORDER BY created_at DESC;
END;
$$ LANGUAGE "plpgsql";

-- =================================================================
--  6. ROW-LEVEL SECURITY (RLS)
-- =================================================================
ALTER TABLE "public"."profiles" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."properties" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."property_ratings" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."chats" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."messages" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."notifications" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."fcm_tokens" ENABLE ROW LEVEL SECURITY; -- Enable RLS for new table

-- Profiles
CREATE POLICY "Allow users to read all profiles" ON "public"."profiles" FOR SELECT USING (true);
CREATE POLICY "Allow users to update their own profile" ON "public"."profiles" FOR UPDATE USING (auth.uid() = id) WITH CHECK (auth.uid() = id);

-- Properties (Unchanged)
CREATE POLICY "Allow public read access to approved properties" ON "public"."properties" FOR SELECT USING (status = 'approved');
CREATE POLICY "Allow landlords to view their own properties" ON "public"."properties" FOR SELECT USING (auth.uid() = landlord_id);
CREATE POLICY "Allow admins full access to properties" ON "public"."properties" FOR ALL USING (is_admin()) WITH CHECK (is_admin());
CREATE POLICY "Allow landlords to manage their own properties" ON "public"."properties" FOR INSERT WITH CHECK (auth.uid() = landlord_id);
CREATE POLICY "Allow landlords to update their own properties" ON "public"."properties" FOR UPDATE USING (auth.uid() = landlord_id);
CREATE POLICY "Allow landlords to delete their own properties" ON "public"."properties" FOR DELETE USING (auth.uid() = landlord_id);

-- Property Ratings (Unchanged)
CREATE POLICY "Allow authenticated read access to all ratings" ON "public"."property_ratings" FOR SELECT TO "authenticated" USING (true);
CREATE POLICY "Allow users to manage their own ratings" ON "public"."property_ratings" FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- Chats & Messages (Unchanged)
CREATE POLICY "Allow users to access their own chats" ON "public"."chats" FOR ALL USING (auth.uid() = renter_id OR auth.uid() = landlord_id);
CREATE POLICY "Allow users to access messages in their chats" ON "public"."messages" FOR ALL
  USING (EXISTS (SELECT 1 FROM public.chats WHERE chats.id = messages.chat_id AND (chats.renter_id = auth.uid() OR chats.landlord_id = auth.uid())));

-- Notifications (Unchanged)
CREATE POLICY "Users can view their own notifications" ON "public"."notifications" FOR SELECT USING (recipient_id = auth.uid());
CREATE POLICY "Allow admins to create notifications" ON "public"."notifications" FOR INSERT WITH CHECK (is_admin());

-- FCM Tokens (NEW)
CREATE POLICY "Allow users to manage their own FCM tokens" ON "public"."fcm_tokens" FOR ALL
  USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- =================================================================
--  7. GRANTS
-- =================================================================
GRANT USAGE ON SCHEMA "public" TO "postgres", "anon", "authenticated", "service_role";
GRANT ALL ON ALL TABLES IN SCHEMA "public" TO "postgres", "service_role";
GRANT ALL ON ALL FUNCTIONS IN SCHEMA "public" TO "postgres", "service_role";
GRANT ALL ON ALL SEQUENCES IN SCHEMA "public" TO "postgres", "service_role";
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA "public" TO "authenticated";
GRANT SELECT ON ALL TABLES IN SCHEMA "public" TO "anon";
ALTER DEFAULT PRIVILEGES IN SCHEMA "public" GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO "authenticated";
ALTER DEFAULT PRIVILEGES IN SCHEMA "public" GRANT SELECT ON TABLES TO "anon";
