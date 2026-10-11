-- =========================================================================
-- SEED DATA: 114 AUTHENTIC KERALA DUMMY PROFILES (57 BOYS, 57 GIRLS)
-- FOR KURICHIYAR Matrimony - With Malayalam Details and IS_DUMMY set to true
-- =========================================================================

-- 1. Ensure the is_dummy column exists in the kurichiyar_profiles table
ALTER TABLE public.kurichiyar_profiles ADD COLUMN IF NOT EXISTS is_dummy BOOLEAN DEFAULT false;

-- 2. Ensure the is_dummy column exists in public.profiles (if the table exists)
DO $$
BEGIN
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'profiles') THEN
        ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS is_dummy BOOLEAN DEFAULT false;
    END IF;
END $$;

-- 3. Insert into auth.users
INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at, role, aud, raw_app_meta_data, raw_user_meta_data)
VALUES (
  'ded869f2-c973-40b0-88ed-39de10b3835b',
  'dummy_boy_1@auth.kurichiyar.com',
  crypt('password123', gen_salt('bf')),
  now(),
  now(),
  now(),
  'authenticated',
  'authenticated',
  '{"provider":"email","providers":["email"]}'::jsonb,
  '{"phone_number":"+919900010000"}'::jsonb
);
INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at, role, aud, raw_app_meta_data, raw_user_meta_data)
VALUES (
  '61a600c4-c1c1-4c83-afaf-c6dedac22fab',
  'dummy_boy_2@auth.kurichiyar.com',
  crypt('password123', gen_salt('bf')),
  now(),
  now(),
  now(),
  'authenticated',
  'authenticated',
  '{"provider":"email","providers":["email"]}'::jsonb,
  '{"phone_number":"+919900010001"}'::jsonb
);
INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at, role, aud, raw_app_meta_data, raw_user_meta_data)
VALUES (
  'e1e129c3-77b2-4def-9885-92b740f79411',
  'dummy_boy_3@auth.kurichiyar.com',
  crypt('password123', gen_salt('bf')),
  now(),
  now(),
  now(),
  'authenticated',
  'authenticated',
  '{"provider":"email","providers":["email"]}'::jsonb,
  '{"phone_number":"+919900010002"}'::jsonb
);
INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at, role, aud, raw_app_meta_data, raw_user_meta_data)
VALUES (
  '7037d077-0069-48bc-a9e3-d2e428e71f39',
  'dummy_boy_4@auth.kurichiyar.com',
  crypt('password123', gen_salt('bf')),
  now(),
  now(),
  now(),
  'authenticated',
  'authenticated',
  '{"provider":"email","providers":["email"]}'::jsonb,
  '{"phone_number":"+919900010003"}'::jsonb
);
INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at, role, aud, raw_app_meta_data, raw_user_meta_data)
VALUES (
  'ffd7f932-f02c-4090-97da-fb20e608de1c',
  'dummy_boy_5@auth.kurichiyar.com',
  crypt('password123', gen_salt('bf')),
  now(),
  now(),
  now(),
  'authenticated',
  'authenticated',
  '{"provider":"email","providers":["email"]}'::jsonb,
  '{"phone_number":"+919900010004"}'::jsonb
);
INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at, role, aud, raw_app_meta_data, raw_user_meta_data)
VALUES (
  '5ab8b66b-2600-4880-bc32-029e8da85b9d',
  'dummy_boy_6@auth.kurichiyar.com',
  crypt('password123', gen_salt('bf')),
  now(),
  now(),
  now(),
  'authenticated',
  'authenticated',
  '{"provider":"email","providers":["email"]}'::jsonb,
  '{"phone_number":"+919900010005"}'::jsonb
);
INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at, role, aud, raw_app_meta_data, raw_user_meta_data)
VALUES (
  'e01b6bde-0da3-4fa4-b3d3-77197b82c742',
  'dummy_boy_7@auth.kurichiyar.com',
  crypt('password123', gen_salt('bf')),
  now(),
  now(),
  now(),
  'authenticated',
  'authenticated',
  '{"provider":"email","providers":["email"]}'::jsonb,
  '{"phone_number":"+919900010006"}'::jsonb
);
INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at, role, aud, raw_app_meta_data, raw_user_meta_data)
VALUES (
  'b5da801a-07bc-4f61-9dde-160d854a1303',
  'dummy_boy_8@auth.kurichiyar.com',
  crypt('password123', gen_salt('bf')),
  now(),
  now(),
  now(),
  'authenticated',
  'authenticated',
  '{"provider":"email","providers":["email"]}'::jsonb,
  '{"phone_number":"+919900010007"}'::jsonb
);
INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at, role, aud, raw_app_meta_data, raw_user_meta_data)
VALUES (
  '52d63c4d-3fa6-47af-aaa5-c8b609832a0a',
  'dummy_boy_9@auth.kurichiyar.com',
  crypt('password123', gen_salt('bf')),
  now(),
  now(),
  now(),
  'authenticated',
  'authenticated',
  '{"provider":"email","providers":["email"]}'::jsonb,
  '{"phone_number":"+919900010008"}'::jsonb
);
INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at, role, aud, raw_app_meta_data, raw_user_meta_data)
VALUES (
  '337ec196-e69c-48d5-8cec-27d04668353e',
  'dummy_boy_10@auth.kurichiyar.com',
  crypt('password123', gen_salt('bf')),
  now(),
  now(),
  now(),
  'authenticated',
  'authenticated',
  '{"provider":"email","providers":["email"]}'::jsonb,
  '{"phone_number":"+919900010009"}'::jsonb
);
INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at, role, aud, raw_app_meta_data, raw_user_meta_data)
VALUES (
  '17eec9df-5591-4ddc-8636-68b74b65d749',
  'dummy_boy_11@auth.kurichiyar.com',
  crypt('password123', gen_salt('bf')),
  now(),
  now(),
  now(),
  'authenticated',
  'authenticated',
  '{"provider":"email","providers":["email"]}'::jsonb,
  '{"phone_number":"+919900010010"}'::jsonb
);
INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at, role, aud, raw_app_meta_data, raw_user_meta_data)
VALUES (
  '7a1f0b2b-ee0c-43c3-9297-0484016530fe',
  'dummy_boy_12@auth.kurichiyar.com',
  crypt('password123', gen_salt('bf')),
  now(),
  now(),
  now(),
  'authenticated',
  'authenticated',
  '{"provider":"email","providers":["email"]}'::jsonb,
  '{"phone_number":"+919900010011"}'::jsonb
);
INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at, role, aud, raw_app_meta_data, raw_user_meta_data)
VALUES (
  '88d65b16-9265-42fb-9948-e1485c2e3a07',
  'dummy_boy_13@auth.kurichiyar.com',
  crypt('password123', gen_salt('bf')),
  now(),
  now(),
  now(),
  'authenticated',
  'authenticated',
  '{"provider":"email","providers":["email"]}'::jsonb,
  '{"phone_number":"+919900010012"}'::jsonb
);
INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at, role, aud, raw_app_meta_data, raw_user_meta_data)
VALUES (
  '34dd5e74-aa9d-4da9-82d5-ac3bd243e74d',
  'dummy_boy_14@auth.kurichiyar.com',
  crypt('password123', gen_salt('bf')),
  now(),
  now(),
  now(),
  'authenticated',
  'authenticated',
  '{"provider":"email","providers":["email"]}'::jsonb,
  '{"phone_number":"+919900010013"}'::jsonb
);
INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at, role, aud, raw_app_meta_data, raw_user_meta_data)
VALUES (
  'e55277b9-488c-4d61-84c3-c5f66d1a3bf8',
  'dummy_boy_15@auth.kurichiyar.com',
  crypt('password123', gen_salt('bf')),
  now(),
  now(),
  now(),
  'authenticated',
  'authenticated',
  '{"provider":"email","providers":["email"]}'::jsonb,
  '{"phone_number":"+919900010014"}'::jsonb
);
INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at, role, aud, raw_app_meta_data, raw_user_meta_data)
VALUES (
  '5e1c0f1c-51df-47ea-ba7f-5abc5a25316b',
  'dummy_boy_16@auth.kurichiyar.com',
  crypt('password123', gen_salt('bf')),
  now(),
  now(),
  now(),
  'authenticated',
  'authenticated',
  '{"provider":"email","providers":["email"]}'::jsonb,
  '{"phone_number":"+919900010015"}'::jsonb
);
INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at, role, aud, raw_app_meta_data, raw_user_meta_data)
VALUES (
  '2ae5a186-74b5-4596-9c1d-b62b0391f858',
  'dummy_boy_17@auth.kurichiyar.com',
  crypt('password123', gen_salt('bf')),
  now(),
  now(),
  now(),
  'authenticated',
  'authenticated',
  '{"provider":"email","providers":["email"]}'::jsonb,
  '{"phone_number":"+919900010016"}'::jsonb
);
INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at, role, aud, raw_app_meta_data, raw_user_meta_data)
VALUES (
  '0366736d-2b92-49b4-8458-69e9760bdd4a',
  'dummy_boy_18@auth.kurichiyar.com',
  crypt('password123', gen_salt('bf')),
  now(),
  now(),
  now(),
  'authenticated',
  'authenticated',
  '{"provider":"email","providers":["email"]}'::jsonb,
  '{"phone_number":"+919900010017"}'::jsonb
);
INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at, role, aud, raw_app_meta_data, raw_user_meta_data)
VALUES (
  '7c55fee9-f518-4d56-b5ab-329ddcbebc88',
  'dummy_boy_19@auth.kurichiyar.com',
  crypt('password123', gen_salt('bf')),
  now(),
  now(),
  now(),
  'authenticated',
  'authenticated',
  '{"provider":"email","providers":["email"]}'::jsonb,
  '{"phone_number":"+919900010018"}'::jsonb
);
INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at, role, aud, raw_app_meta_data, raw_user_meta_data)
VALUES (
  'c054482d-127b-4faf-ad9d-33fccc19386f',
  'dummy_boy_20@auth.kurichiyar.com',
  crypt('password123', gen_salt('bf')),
  now(),
  now(),
  now(),
  'authenticated',
  'authenticated',
  '{"provider":"email","providers":["email"]}'::jsonb,
  '{"phone_number":"+919900010019"}'::jsonb
);
INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at, role, aud, raw_app_meta_data, raw_user_meta_data)
VALUES (
  '26087f2d-11a6-4ebe-acd0-0227417a6d93',
  'dummy_boy_21@auth.kurichiyar.com',
  crypt('password123', gen_salt('bf')),
  now(),
  now(),
  now(),
  'authenticated',
  'authenticated',
  '{"provider":"email","providers":["email"]}'::jsonb,
  '{"phone_number":"+919900010020"}'::jsonb
);
INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at, role, aud, raw_app_meta_data, raw_user_meta_data)
VALUES (
  '0e81fb12-e35e-4823-a69d-70002b76c62e',
  'dummy_boy_22@auth.kurichiyar.com',
  crypt('password123', gen_salt('bf')),
  now(),
  now(),
  now(),
  'authenticated',
  'authenticated',
  '{"provider":"email","providers":["email"]}'::jsonb,
  '{"phone_number":"+919900010021"}'::jsonb
);
INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at, role, aud, raw_app_meta_data, raw_user_meta_data)
VALUES (
  '886f35ab-739c-4af5-b609-78d9c1981e1e',
  'dummy_boy_23@auth.kurichiyar.com',
  crypt('password123', gen_salt('bf')),
  now(),
  now(),
  now(),
  'authenticated',
  'authenticated',
  '{"provider":"email","providers":["email"]}'::jsonb,
  '{"phone_number":"+919900010022"}'::jsonb
);
INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at, role, aud, raw_app_meta_data, raw_user_meta_data)
VALUES (
  '75f19889-7109-4923-a229-1a07f568923e',
  'dummy_boy_24@auth.kurichiyar.com',
  crypt('password123', gen_salt('bf')),
  now(),
  now(),
  now(),
  'authenticated',
  'authenticated',
  '{"provider":"email","providers":["email"]}'::jsonb,
  '{"phone_number":"+919900010023"}'::jsonb
);
INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at, role, aud, raw_app_meta_data, raw_user_meta_data)
VALUES (
  '09bd04bc-783b-47bf-878b-3bdceaeb0ffb',
  'dummy_boy_25@auth.kurichiyar.com',
  crypt('password123', gen_salt('bf')),
  now(),
  now(),
  now(),
  'authenticated',
  'authenticated',
  '{"provider":"email","providers":["email"]}'::jsonb,
  '{"phone_number":"+919900010024"}'::jsonb
);
INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at, role, aud, raw_app_meta_data, raw_user_meta_data)
VALUES (
  '64b51a70-1a48-4b5c-afea-20618bc456e5',
  'dummy_boy_26@auth.kurichiyar.com',
  crypt('password123', gen_salt('bf')),
  now(),
  now(),
  now(),
  'authenticated',
  'authenticated',
  '{"provider":"email","providers":["email"]}'::jsonb,
  '{"phone_number":"+919900010025"}'::jsonb
);
INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at, role, aud, raw_app_meta_data, raw_user_meta_data)
VALUES (
  'cdd0b5f8-2dc3-4238-943c-67c82352f7b1',
  'dummy_boy_27@auth.kurichiyar.com',
  crypt('password123', gen_salt('bf')),
  now(),
  now(),
  now(),
  'authenticated',
  'authenticated',
  '{"provider":"email","providers":["email"]}'::jsonb,
  '{"phone_number":"+919900010026"}'::jsonb
);
INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at, role, aud, raw_app_meta_data, raw_user_meta_data)
VALUES (
  'b31390c7-0647-42af-8daf-6e6ba9619ac4',
  'dummy_boy_28@auth.kurichiyar.com',
  crypt('password123', gen_salt('bf')),
  now(),
  now(),
  now(),
  'authenticated',
  'authenticated',
  '{"provider":"email","providers":["email"]}'::jsonb,
  '{"phone_number":"+919900010027"}'::jsonb
);
INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at, role, aud, raw_app_meta_data, raw_user_meta_data)
VALUES (
  '84d22bdb-9620-4d88-b88c-b2e9e540d9df',
  'dummy_boy_29@auth.kurichiyar.com',
  crypt('password123', gen_salt('bf')),
  now(),
  now(),
  now(),
  'authenticated',
  'authenticated',
  '{"provider":"email","providers":["email"]}'::jsonb,
  '{"phone_number":"+919900010028"}'::jsonb
);
INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at, role, aud, raw_app_meta_data, raw_user_meta_data)
VALUES (
  '728538c0-b300-41ed-8113-6582318e19b6',
  'dummy_boy_30@auth.kurichiyar.com',
  crypt('password123', gen_salt('bf')),
  now(),
  now(),
  now(),
  'authenticated',
  'authenticated',
  '{"provider":"email","providers":["email"]}'::jsonb,
  '{"phone_number":"+919900010029"}'::jsonb
);
INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at, role, aud, raw_app_meta_data, raw_user_meta_data)
VALUES (
  '45a91ff8-db5f-41a7-8786-8adf7b6a68a7',
  'dummy_boy_31@auth.kurichiyar.com',
  crypt('password123', gen_salt('bf')),
  now(),
  now(),
  now(),
  'authenticated',
  'authenticated',
  '{"provider":"email","providers":["email"]}'::jsonb,
  '{"phone_number":"+919900010030"}'::jsonb
);
INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at, role, aud, raw_app_meta_data, raw_user_meta_data)
VALUES (
  '91627f6b-3ad4-4817-a95a-5939eb1b7de9',
  'dummy_boy_32@auth.kurichiyar.com',
  crypt('password123', gen_salt('bf')),
  now(),
  now(),
  now(),
  'authenticated',
  'authenticated',
  '{"provider":"email","providers":["email"]}'::jsonb,
  '{"phone_number":"+919900010031"}'::jsonb
);
INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at, role, aud, raw_app_meta_data, raw_user_meta_data)
VALUES (
  '8b50311a-d2b9-4ca6-907b-8f964bc7e841',
  'dummy_boy_33@auth.kurichiyar.com',
  crypt('password123', gen_salt('bf')),
  now(),
  now(),
  now(),
  'authenticated',
  'authenticated',
  '{"provider":"email","providers":["email"]}'::jsonb,
  '{"phone_number":"+919900010032"}'::jsonb
);
INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at, role, aud, raw_app_meta_data, raw_user_meta_data)
VALUES (
  '4548b157-2440-44af-9aee-aca67ded68f5',
  'dummy_boy_34@auth.kurichiyar.com',
  crypt('password123', gen_salt('bf')),
  now(),
  now(),
  now(),
  'authenticated',
  'authenticated',
  '{"provider":"email","providers":["email"]}'::jsonb,
  '{"phone_number":"+919900010033"}'::jsonb
);
INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at, role, aud, raw_app_meta_data, raw_user_meta_data)
VALUES (
  '79c5bb3e-d972-472f-8adb-c75b9f2007f6',
  'dummy_boy_35@auth.kurichiyar.com',
  crypt('password123', gen_salt('bf')),
  now(),
  now(),
  now(),
  'authenticated',
  'authenticated',
  '{"provider":"email","providers":["email"]}'::jsonb,
  '{"phone_number":"+919900010034"}'::jsonb
);
INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at, role, aud, raw_app_meta_data, raw_user_meta_data)
VALUES (
  '24f1fc20-aae9-4454-9baa-baefeb7950e3',
  'dummy_boy_36@auth.kurichiyar.com',
  crypt('password123', gen_salt('bf')),
  now(),
  now(),
  now(),
  'authenticated',
  'authenticated',
  '{"provider":"email","providers":["email"]}'::jsonb,
  '{"phone_number":"+919900010035"}'::jsonb
);
INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at, role, aud, raw_app_meta_data, raw_user_meta_data)
VALUES (
  '68f34e9e-00e4-4fc7-8556-22f83fd2e5a8',
  'dummy_boy_37@auth.kurichiyar.com',
  crypt('password123', gen_salt('bf')),
  now(),
  now(),
  now(),
  'authenticated',
  'authenticated',
  '{"provider":"email","providers":["email"]}'::jsonb,
  '{"phone_number":"+919900010036"}'::jsonb
);
INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at, role, aud, raw_app_meta_data, raw_user_meta_data)
VALUES (
  '27932b2f-ac26-4e1a-a995-0c419e881797',
  'dummy_boy_38@auth.kurichiyar.com',
  crypt('password123', gen_salt('bf')),
  now(),
  now(),
  now(),
  'authenticated',
  'authenticated',
  '{"provider":"email","providers":["email"]}'::jsonb,
  '{"phone_number":"+919900010037"}'::jsonb
);
INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at, role, aud, raw_app_meta_data, raw_user_meta_data)
VALUES (
  '20a91055-01e1-463c-9d79-469a5885feca',
  'dummy_boy_39@auth.kurichiyar.com',
  crypt('password123', gen_salt('bf')),
  now(),
  now(),
  now(),
  'authenticated',
  'authenticated',
  '{"provider":"email","providers":["email"]}'::jsonb,
  '{"phone_number":"+919900010038"}'::jsonb
);
INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at, role, aud, raw_app_meta_data, raw_user_meta_data)
VALUES (
  '5046e7de-e1aa-436b-8c9a-7f059f045289',
  'dummy_boy_40@auth.kurichiyar.com',
  crypt('password123', gen_salt('bf')),
  now(),
  now(),
  now(),
  'authenticated',
  'authenticated',
  '{"provider":"email","providers":["email"]}'::jsonb,
  '{"phone_number":"+919900010039"}'::jsonb
);
INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at, role, aud, raw_app_meta_data, raw_user_meta_data)
VALUES (
  '7575f9f3-2488-4045-bf0e-b0050c32c9ee',
  'dummy_boy_41@auth.kurichiyar.com',
  crypt('password123', gen_salt('bf')),
  now(),
  now(),
  now(),
  'authenticated',
  'authenticated',
  '{"provider":"email","providers":["email"]}'::jsonb,
  '{"phone_number":"+919900010040"}'::jsonb
);
INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at, role, aud, raw_app_meta_data, raw_user_meta_data)
VALUES (
  '26ffe558-540c-4e5c-b6cf-d9fdc5e4f237',
  'dummy_boy_42@auth.kurichiyar.com',
  crypt('password123', gen_salt('bf')),
  now(),
  now(),
  now(),
  'authenticated',
  'authenticated',
  '{"provider":"email","providers":["email"]}'::jsonb,
  '{"phone_number":"+919900010041"}'::jsonb
);
INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at, role, aud, raw_app_meta_data, raw_user_meta_data)
VALUES (
  '423797cb-ef2b-4c54-ba84-326dc9a95781',
  'dummy_boy_43@auth.kurichiyar.com',
  crypt('password123', gen_salt('bf')),
  now(),
  now(),
  now(),
  'authenticated',
  'authenticated',
  '{"provider":"email","providers":["email"]}'::jsonb,
  '{"phone_number":"+919900010042"}'::jsonb
);
INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at, role, aud, raw_app_meta_data, raw_user_meta_data)
VALUES (
  '4c801080-2806-4248-9aee-bc00d54cf147',
  'dummy_boy_44@auth.kurichiyar.com',
  crypt('password123', gen_salt('bf')),
  now(),
  now(),
  now(),
  'authenticated',
  'authenticated',
  '{"provider":"email","providers":["email"]}'::jsonb,
  '{"phone_number":"+919900010043"}'::jsonb
);
INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at, role, aud, raw_app_meta_data, raw_user_meta_data)
VALUES (
  'f485ffca-f90e-4738-b94e-8795e0671f4e',
  'dummy_boy_45@auth.kurichiyar.com',
  crypt('password123', gen_salt('bf')),
  now(),
  now(),
  now(),
  'authenticated',
  'authenticated',
  '{"provider":"email","providers":["email"]}'::jsonb,
  '{"phone_number":"+919900010044"}'::jsonb
);
INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at, role, aud, raw_app_meta_data, raw_user_meta_data)
VALUES (
  '786381e7-38da-4ff2-bd01-d3c11419750f',
  'dummy_boy_46@auth.kurichiyar.com',
  crypt('password123', gen_salt('bf')),
  now(),
  now(),
  now(),
  'authenticated',
  'authenticated',
  '{"provider":"email","providers":["email"]}'::jsonb,
  '{"phone_number":"+919900010045"}'::jsonb
);
INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at, role, aud, raw_app_meta_data, raw_user_meta_data)
VALUES (
  '8c3411df-f09e-4ce8-9271-a8d750ccb4fd',
  'dummy_boy_47@auth.kurichiyar.com',
  crypt('password123', gen_salt('bf')),
  now(),
  now(),
  now(),
  'authenticated',
  'authenticated',
  '{"provider":"email","providers":["email"]}'::jsonb,
  '{"phone_number":"+919900010046"}'::jsonb
);
INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at, role, aud, raw_app_meta_data, raw_user_meta_data)
VALUES (
  '973fb2b9-2d66-494c-9b26-5a6aefaaf200',
  'dummy_boy_48@auth.kurichiyar.com',
  crypt('password123', gen_salt('bf')),
  now(),
  now(),
  now(),
  'authenticated',
  'authenticated',
  '{"provider":"email","providers":["email"]}'::jsonb,
  '{"phone_number":"+919900010047"}'::jsonb
);
INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at, role, aud, raw_app_meta_data, raw_user_meta_data)
VALUES (
  '7a79327c-f145-41c5-84e4-fbf1614b52a8',
  'dummy_boy_49@auth.kurichiyar.com',
  crypt('password123', gen_salt('bf')),
  now(),
  now(),
  now(),
  'authenticated',
  'authenticated',
  '{"provider":"email","providers":["email"]}'::jsonb,
  '{"phone_number":"+919900010048"}'::jsonb
);
INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at, role, aud, raw_app_meta_data, raw_user_meta_data)
VALUES (
  'dbb968cb-19ca-4ab7-af40-3756394ead53',
  'dummy_boy_50@auth.kurichiyar.com',
  crypt('password123', gen_salt('bf')),
  now(),
  now(),
  now(),
  'authenticated',
  'authenticated',
  '{"provider":"email","providers":["email"]}'::jsonb,
  '{"phone_number":"+919900010049"}'::jsonb
);
INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at, role, aud, raw_app_meta_data, raw_user_meta_data)
VALUES (
  '4c92a8e3-faf0-4eb8-b115-e62b763dcc3f',
  'dummy_boy_51@auth.kurichiyar.com',
  crypt('password123', gen_salt('bf')),
  now(),
  now(),
  now(),
  'authenticated',
  'authenticated',
  '{"provider":"email","providers":["email"]}'::jsonb,
  '{"phone_number":"+919900010050"}'::jsonb
);
INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at, role, aud, raw_app_meta_data, raw_user_meta_data)
VALUES (
  'aa2d15dc-5de5-4848-af2d-c3f514d208f8',
  'dummy_boy_52@auth.kurichiyar.com',
  crypt('password123', gen_salt('bf')),
  now(),
  now(),
  now(),
  'authenticated',
  'authenticated',
  '{"provider":"email","providers":["email"]}'::jsonb,
  '{"phone_number":"+919900010051"}'::jsonb
);
INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at, role, aud, raw_app_meta_data, raw_user_meta_data)
VALUES (
  'adcdca3b-a898-4d31-a209-58537452e477',
  'dummy_boy_53@auth.kurichiyar.com',
  crypt('password123', gen_salt('bf')),
  now(),
  now(),
  now(),
  'authenticated',
  'authenticated',
  '{"provider":"email","providers":["email"]}'::jsonb,
  '{"phone_number":"+919900010052"}'::jsonb
);
INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at, role, aud, raw_app_meta_data, raw_user_meta_data)
VALUES (
  'de157d2e-a1c8-4f72-b071-562e2ff3bff7',
  'dummy_boy_54@auth.kurichiyar.com',
  crypt('password123', gen_salt('bf')),
  now(),
  now(),
  now(),
  'authenticated',
  'authenticated',
  '{"provider":"email","providers":["email"]}'::jsonb,
  '{"phone_number":"+919900010053"}'::jsonb
);
INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at, role, aud, raw_app_meta_data, raw_user_meta_data)
VALUES (
  'bde1992b-1095-406b-918a-12c03cc7a8e9',
  'dummy_boy_55@auth.kurichiyar.com',
  crypt('password123', gen_salt('bf')),
  now(),
  now(),
  now(),
  'authenticated',
  'authenticated',
  '{"provider":"email","providers":["email"]}'::jsonb,
  '{"phone_number":"+919900010054"}'::jsonb
);
INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at, role, aud, raw_app_meta_data, raw_user_meta_data)
VALUES (
  'e9bb5c03-0087-4fa0-8c3d-07aedd0627e5',
  'dummy_boy_56@auth.kurichiyar.com',
  crypt('password123', gen_salt('bf')),
  now(),
  now(),
  now(),
  'authenticated',
  'authenticated',
  '{"provider":"email","providers":["email"]}'::jsonb,
  '{"phone_number":"+919900010055"}'::jsonb
);
INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at, role, aud, raw_app_meta_data, raw_user_meta_data)
VALUES (
  '32c91873-a455-43d1-982a-199faf061814',
  'dummy_boy_57@auth.kurichiyar.com',
  crypt('password123', gen_salt('bf')),
  now(),
  now(),
  now(),
  'authenticated',
  'authenticated',
  '{"provider":"email","providers":["email"]}'::jsonb,
  '{"phone_number":"+919900010056"}'::jsonb
);
INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at, role, aud, raw_app_meta_data, raw_user_meta_data)
VALUES (
  'e529b89b-54ee-4337-bb48-36446ff9c027',
  'dummy_girl_1@auth.kurichiyar.com',
  crypt('password123', gen_salt('bf')),
  now(),
  now(),
  now(),
  'authenticated',
  'authenticated',
  '{"provider":"email","providers":["email"]}'::jsonb,
  '{"phone_number":"+919900020000"}'::jsonb
);
INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at, role, aud, raw_app_meta_data, raw_user_meta_data)
VALUES (
  '64dd6f70-e0c7-4996-8ef1-41bddbece35a',
  'dummy_girl_2@auth.kurichiyar.com',
  crypt('password123', gen_salt('bf')),
  now(),
  now(),
  now(),
  'authenticated',
  'authenticated',
  '{"provider":"email","providers":["email"]}'::jsonb,
  '{"phone_number":"+919900020001"}'::jsonb
);
INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at, role, aud, raw_app_meta_data, raw_user_meta_data)
VALUES (
  '8e4fe080-e41e-4580-847c-28bf797b0b40',
  'dummy_girl_3@auth.kurichiyar.com',
  crypt('password123', gen_salt('bf')),
  now(),
  now(),
  now(),
  'authenticated',
  'authenticated',
  '{"provider":"email","providers":["email"]}'::jsonb,
  '{"phone_number":"+919900020002"}'::jsonb
);
INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at, role, aud, raw_app_meta_data, raw_user_meta_data)
VALUES (
  'ed310172-f1cd-4ab5-aa99-bd5d1581aec3',
  'dummy_girl_4@auth.kurichiyar.com',
  crypt('password123', gen_salt('bf')),
  now(),
  now(),
  now(),
  'authenticated',
  'authenticated',
  '{"provider":"email","providers":["email"]}'::jsonb,
  '{"phone_number":"+919900020003"}'::jsonb
);
INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at, role, aud, raw_app_meta_data, raw_user_meta_data)
VALUES (
  '58bd47ff-b05c-484a-a854-8804b7361d4f',
  'dummy_girl_5@auth.kurichiyar.com',
  crypt('password123', gen_salt('bf')),
  now(),
  now(),
  now(),
  'authenticated',
  'authenticated',
  '{"provider":"email","providers":["email"]}'::jsonb,
  '{"phone_number":"+919900020004"}'::jsonb
);
INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at, role, aud, raw_app_meta_data, raw_user_meta_data)
VALUES (
  '468fcbb2-f414-4b46-80d1-e2755a977e1c',
  'dummy_girl_6@auth.kurichiyar.com',
  crypt('password123', gen_salt('bf')),
  now(),
  now(),
  now(),
  'authenticated',
  'authenticated',
  '{"provider":"email","providers":["email"]}'::jsonb,
  '{"phone_number":"+919900020005"}'::jsonb
);
INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at, role, aud, raw_app_meta_data, raw_user_meta_data)
VALUES (
  'd42e979a-fbf4-4da5-b625-b05b3e0f2da5',
  'dummy_girl_7@auth.kurichiyar.com',
  crypt('password123', gen_salt('bf')),
  now(),
  now(),
  now(),
  'authenticated',
  'authenticated',
  '{"provider":"email","providers":["email"]}'::jsonb,
  '{"phone_number":"+919900020006"}'::jsonb
);
INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at, role, aud, raw_app_meta_data, raw_user_meta_data)
VALUES (
  '7857ca13-6dfc-4204-80e4-a22a87f6b83b',
  'dummy_girl_8@auth.kurichiyar.com',
  crypt('password123', gen_salt('bf')),
  now(),
  now(),
  now(),
  'authenticated',
  'authenticated',
  '{"provider":"email","providers":["email"]}'::jsonb,
  '{"phone_number":"+919900020007"}'::jsonb
);
INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at, role, aud, raw_app_meta_data, raw_user_meta_data)
VALUES (
  'b45928d8-e863-4c47-a94b-cbb4f90c03b6',
  'dummy_girl_9@auth.kurichiyar.com',
  crypt('password123', gen_salt('bf')),
  now(),
  now(),
  now(),
  'authenticated',
  'authenticated',
  '{"provider":"email","providers":["email"]}'::jsonb,
  '{"phone_number":"+919900020008"}'::jsonb
);
INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at, role, aud, raw_app_meta_data, raw_user_meta_data)
VALUES (
  '752359a2-657a-4fda-95f0-36ecebf5a479',
  'dummy_girl_10@auth.kurichiyar.com',
  crypt('password123', gen_salt('bf')),
  now(),
  now(),
  now(),
  'authenticated',
  'authenticated',
  '{"provider":"email","providers":["email"]}'::jsonb,
  '{"phone_number":"+919900020009"}'::jsonb
);
INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at, role, aud, raw_app_meta_data, raw_user_meta_data)
VALUES (
  '530a18b4-b0f5-4355-9b26-41a4bd8da96d',
  'dummy_girl_11@auth.kurichiyar.com',
  crypt('password123', gen_salt('bf')),
  now(),
  now(),
  now(),
  'authenticated',
  'authenticated',
  '{"provider":"email","providers":["email"]}'::jsonb,
  '{"phone_number":"+919900020010"}'::jsonb
);
INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at, role, aud, raw_app_meta_data, raw_user_meta_data)
VALUES (
  '95fa5d88-dd76-4828-a384-e1bb3ec3f048',
  'dummy_girl_12@auth.kurichiyar.com',
  crypt('password123', gen_salt('bf')),
  now(),
  now(),
  now(),
  'authenticated',
  'authenticated',
  '{"provider":"email","providers":["email"]}'::jsonb,
  '{"phone_number":"+919900020011"}'::jsonb
);
INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at, role, aud, raw_app_meta_data, raw_user_meta_data)
VALUES (
  '2374d0eb-3db6-4cda-8b1a-7b1b22b839b5',
  'dummy_girl_13@auth.kurichiyar.com',
  crypt('password123', gen_salt('bf')),
  now(),
  now(),
  now(),
  'authenticated',
  'authenticated',
  '{"provider":"email","providers":["email"]}'::jsonb,
  '{"phone_number":"+919900020012"}'::jsonb
);
INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at, role, aud, raw_app_meta_data, raw_user_meta_data)
VALUES (
  'bee7589d-d3c2-4e5b-ab53-9f49c230b822',
  'dummy_girl_14@auth.kurichiyar.com',
  crypt('password123', gen_salt('bf')),
  now(),
  now(),
  now(),
  'authenticated',
  'authenticated',
  '{"provider":"email","providers":["email"]}'::jsonb,
  '{"phone_number":"+919900020013"}'::jsonb
);
INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at, role, aud, raw_app_meta_data, raw_user_meta_data)
VALUES (
  '3b283d73-9bc7-4798-a8eb-2e547cb09c10',
  'dummy_girl_15@auth.kurichiyar.com',
  crypt('password123', gen_salt('bf')),
  now(),
  now(),
  now(),
  'authenticated',
  'authenticated',
  '{"provider":"email","providers":["email"]}'::jsonb,
  '{"phone_number":"+919900020014"}'::jsonb
);
INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at, role, aud, raw_app_meta_data, raw_user_meta_data)
VALUES (
  '0509c136-d9b2-4860-9ac1-68d0bc5ed62c',
  'dummy_girl_16@auth.kurichiyar.com',
  crypt('password123', gen_salt('bf')),
  now(),
  now(),
  now(),
  'authenticated',
  'authenticated',
  '{"provider":"email","providers":["email"]}'::jsonb,
  '{"phone_number":"+919900020015"}'::jsonb
);
INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at, role, aud, raw_app_meta_data, raw_user_meta_data)
VALUES (
  '87596c56-2865-4c83-a4c7-805c567fee49',
  'dummy_girl_17@auth.kurichiyar.com',
  crypt('password123', gen_salt('bf')),
  now(),
  now(),
  now(),
  'authenticated',
  'authenticated',
  '{"provider":"email","providers":["email"]}'::jsonb,
  '{"phone_number":"+919900020016"}'::jsonb
);
INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at, role, aud, raw_app_meta_data, raw_user_meta_data)
VALUES (
  '4563119b-6107-4d79-a603-4b10797176d7',
  'dummy_girl_18@auth.kurichiyar.com',
  crypt('password123', gen_salt('bf')),
  now(),
  now(),
  now(),
  'authenticated',
  'authenticated',
  '{"provider":"email","providers":["email"]}'::jsonb,
  '{"phone_number":"+919900020017"}'::jsonb
);
INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at, role, aud, raw_app_meta_data, raw_user_meta_data)
VALUES (
  'a377297a-61eb-4b21-befd-929271047b7c',
  'dummy_girl_19@auth.kurichiyar.com',
  crypt('password123', gen_salt('bf')),
  now(),
  now(),
  now(),
  'authenticated',
  'authenticated',
  '{"provider":"email","providers":["email"]}'::jsonb,
  '{"phone_number":"+919900020018"}'::jsonb
);
INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at, role, aud, raw_app_meta_data, raw_user_meta_data)
VALUES (
  '3d930cd2-cd35-4bc6-8526-0b75ad7ad0a9',
  'dummy_girl_20@auth.kurichiyar.com',
  crypt('password123', gen_salt('bf')),
  now(),
  now(),
  now(),
  'authenticated',
  'authenticated',
  '{"provider":"email","providers":["email"]}'::jsonb,
  '{"phone_number":"+919900020019"}'::jsonb
);
INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at, role, aud, raw_app_meta_data, raw_user_meta_data)
VALUES (
  '7fb223c1-3290-4f80-ad1a-8baacc144388',
  'dummy_girl_21@auth.kurichiyar.com',
  crypt('password123', gen_salt('bf')),
  now(),
  now(),
  now(),
  'authenticated',
  'authenticated',
  '{"provider":"email","providers":["email"]}'::jsonb,
  '{"phone_number":"+919900020020"}'::jsonb
);
INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at, role, aud, raw_app_meta_data, raw_user_meta_data)
VALUES (
  '1eec5a08-3629-4612-8329-dd20e23c7ad3',
  'dummy_girl_22@auth.kurichiyar.com',
  crypt('password123', gen_salt('bf')),
  now(),
  now(),
  now(),
  'authenticated',
  'authenticated',
  '{"provider":"email","providers":["email"]}'::jsonb,
  '{"phone_number":"+919900020021"}'::jsonb
);
INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at, role, aud, raw_app_meta_data, raw_user_meta_data)
VALUES (
  '22ee5a30-390c-4e54-a041-316072ad310d',
  'dummy_girl_23@auth.kurichiyar.com',
  crypt('password123', gen_salt('bf')),
  now(),
  now(),
  now(),
  'authenticated',
  'authenticated',
  '{"provider":"email","providers":["email"]}'::jsonb,
  '{"phone_number":"+919900020022"}'::jsonb
);
INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at, role, aud, raw_app_meta_data, raw_user_meta_data)
VALUES (
  '8334d4a7-abba-4ef8-ad5f-138ffbd9987a',
  'dummy_girl_24@auth.kurichiyar.com',
  crypt('password123', gen_salt('bf')),
  now(),
  now(),
  now(),
  'authenticated',
  'authenticated',
  '{"provider":"email","providers":["email"]}'::jsonb,
  '{"phone_number":"+919900020023"}'::jsonb
);
INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at, role, aud, raw_app_meta_data, raw_user_meta_data)
VALUES (
  'd85df924-4849-499b-81c5-424087e7518b',
  'dummy_girl_25@auth.kurichiyar.com',
  crypt('password123', gen_salt('bf')),
  now(),
  now(),
  now(),
  'authenticated',
  'authenticated',
  '{"provider":"email","providers":["email"]}'::jsonb,
  '{"phone_number":"+919900020024"}'::jsonb
);
INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at, role, aud, raw_app_meta_data, raw_user_meta_data)
VALUES (
  '24ae5f4f-89ae-4305-a521-48a78eb4c6b4',
  'dummy_girl_26@auth.kurichiyar.com',
  crypt('password123', gen_salt('bf')),
  now(),
  now(),
  now(),
  'authenticated',
  'authenticated',
  '{"provider":"email","providers":["email"]}'::jsonb,
  '{"phone_number":"+919900020025"}'::jsonb
);
INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at, role, aud, raw_app_meta_data, raw_user_meta_data)
VALUES (
  '909c4ee4-a206-4bf1-a1a7-2f7ac5233d4a',
  'dummy_girl_27@auth.kurichiyar.com',
  crypt('password123', gen_salt('bf')),
  now(),
  now(),
  now(),
  'authenticated',
  'authenticated',
  '{"provider":"email","providers":["email"]}'::jsonb,
  '{"phone_number":"+919900020026"}'::jsonb
);
INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at, role, aud, raw_app_meta_data, raw_user_meta_data)
VALUES (
  '211ba6b6-0b87-4eee-ad7f-57aa261f3131',
  'dummy_girl_28@auth.kurichiyar.com',
  crypt('password123', gen_salt('bf')),
  now(),
  now(),
  now(),
  'authenticated',
  'authenticated',
  '{"provider":"email","providers":["email"]}'::jsonb,
  '{"phone_number":"+919900020027"}'::jsonb
);
INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at, role, aud, raw_app_meta_data, raw_user_meta_data)
VALUES (
  'b1d519bd-b83d-4596-9174-cc99dcf0a30d',
  'dummy_girl_29@auth.kurichiyar.com',
  crypt('password123', gen_salt('bf')),
  now(),
  now(),
  now(),
  'authenticated',
  'authenticated',
  '{"provider":"email","providers":["email"]}'::jsonb,
  '{"phone_number":"+919900020028"}'::jsonb
);
INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at, role, aud, raw_app_meta_data, raw_user_meta_data)
VALUES (
  'd1363d34-3167-41a3-8311-2ee6cf4f0c75',
  'dummy_girl_30@auth.kurichiyar.com',
  crypt('password123', gen_salt('bf')),
  now(),
  now(),
  now(),
  'authenticated',
  'authenticated',
  '{"provider":"email","providers":["email"]}'::jsonb,
  '{"phone_number":"+919900020029"}'::jsonb
);
INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at, role, aud, raw_app_meta_data, raw_user_meta_data)
VALUES (
  '29c3316b-b97c-46a5-a9a8-ed281b93c5e5',
  'dummy_girl_31@auth.kurichiyar.com',
  crypt('password123', gen_salt('bf')),
  now(),
  now(),
  now(),
  'authenticated',
  'authenticated',
  '{"provider":"email","providers":["email"]}'::jsonb,
  '{"phone_number":"+919900020030"}'::jsonb
);
INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at, role, aud, raw_app_meta_data, raw_user_meta_data)
VALUES (
  '870c5838-46b8-4266-b0df-848c45f9ce1a',
  'dummy_girl_32@auth.kurichiyar.com',
  crypt('password123', gen_salt('bf')),
  now(),
  now(),
  now(),
  'authenticated',
  'authenticated',
  '{"provider":"email","providers":["email"]}'::jsonb,
  '{"phone_number":"+919900020031"}'::jsonb
);
INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at, role, aud, raw_app_meta_data, raw_user_meta_data)
VALUES (
  'ae802044-3343-4b83-acb8-40d0ccd97fd5',
  'dummy_girl_33@auth.kurichiyar.com',
  crypt('password123', gen_salt('bf')),
  now(),
  now(),
  now(),
  'authenticated',
  'authenticated',
  '{"provider":"email","providers":["email"]}'::jsonb,
  '{"phone_number":"+919900020032"}'::jsonb
);
INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at, role, aud, raw_app_meta_data, raw_user_meta_data)
VALUES (
  'aa5b22bb-2d0a-4b7f-b01f-473868c7cd4f',
  'dummy_girl_34@auth.kurichiyar.com',
  crypt('password123', gen_salt('bf')),
  now(),
  now(),
  now(),
  'authenticated',
  'authenticated',
  '{"provider":"email","providers":["email"]}'::jsonb,
  '{"phone_number":"+919900020033"}'::jsonb
);
INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at, role, aud, raw_app_meta_data, raw_user_meta_data)
VALUES (
  '18d1fab1-9fa9-4094-a93d-2fa1c70a7f50',
  'dummy_girl_35@auth.kurichiyar.com',
  crypt('password123', gen_salt('bf')),
  now(),
  now(),
  now(),
  'authenticated',
  'authenticated',
  '{"provider":"email","providers":["email"]}'::jsonb,
  '{"phone_number":"+919900020034"}'::jsonb
);
INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at, role, aud, raw_app_meta_data, raw_user_meta_data)
VALUES (
  '6816c332-a78b-4146-b77c-74118e69f2e0',
  'dummy_girl_36@auth.kurichiyar.com',
  crypt('password123', gen_salt('bf')),
  now(),
  now(),
  now(),
  'authenticated',
  'authenticated',
  '{"provider":"email","providers":["email"]}'::jsonb,
  '{"phone_number":"+919900020035"}'::jsonb
);
INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at, role, aud, raw_app_meta_data, raw_user_meta_data)
VALUES (
  '38921965-6d1c-4cc4-9fef-6e6cf27f663b',
  'dummy_girl_37@auth.kurichiyar.com',
  crypt('password123', gen_salt('bf')),
  now(),
  now(),
  now(),
  'authenticated',
  'authenticated',
  '{"provider":"email","providers":["email"]}'::jsonb,
  '{"phone_number":"+919900020036"}'::jsonb
);
INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at, role, aud, raw_app_meta_data, raw_user_meta_data)
VALUES (
  'fa75522f-c756-42ff-a7d8-184618c163dc',
  'dummy_girl_38@auth.kurichiyar.com',
  crypt('password123', gen_salt('bf')),
  now(),
  now(),
  now(),
  'authenticated',
  'authenticated',
  '{"provider":"email","providers":["email"]}'::jsonb,
  '{"phone_number":"+919900020037"}'::jsonb
);
INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at, role, aud, raw_app_meta_data, raw_user_meta_data)
VALUES (
  '2ded6bc9-5d55-4a6c-9ce4-77b166acd5c0',
  'dummy_girl_39@auth.kurichiyar.com',
  crypt('password123', gen_salt('bf')),
  now(),
  now(),
  now(),
  'authenticated',
  'authenticated',
  '{"provider":"email","providers":["email"]}'::jsonb,
  '{"phone_number":"+919900020038"}'::jsonb
);
INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at, role, aud, raw_app_meta_data, raw_user_meta_data)
VALUES (
  '1f89b8a9-8b2d-45a6-b346-5dd129b9e0ee',
  'dummy_girl_40@auth.kurichiyar.com',
  crypt('password123', gen_salt('bf')),
  now(),
  now(),
  now(),
  'authenticated',
  'authenticated',
  '{"provider":"email","providers":["email"]}'::jsonb,
  '{"phone_number":"+919900020039"}'::jsonb
);
INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at, role, aud, raw_app_meta_data, raw_user_meta_data)
VALUES (
  '1ca37662-a75f-48b9-b0bb-aa67d689e736',
  'dummy_girl_41@auth.kurichiyar.com',
  crypt('password123', gen_salt('bf')),
  now(),
  now(),
  now(),
  'authenticated',
  'authenticated',
  '{"provider":"email","providers":["email"]}'::jsonb,
  '{"phone_number":"+919900020040"}'::jsonb
);
INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at, role, aud, raw_app_meta_data, raw_user_meta_data)
VALUES (
  '09afadcf-bd24-4275-9816-aa0b70c6ca59',
  'dummy_girl_42@auth.kurichiyar.com',
  crypt('password123', gen_salt('bf')),
  now(),
  now(),
  now(),
  'authenticated',
  'authenticated',
  '{"provider":"email","providers":["email"]}'::jsonb,
  '{"phone_number":"+919900020041"}'::jsonb
);
INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at, role, aud, raw_app_meta_data, raw_user_meta_data)
VALUES (
  '1068e893-390c-4447-a2d6-cc58866b4610',
  'dummy_girl_43@auth.kurichiyar.com',
  crypt('password123', gen_salt('bf')),
  now(),
  now(),
  now(),
  'authenticated',
  'authenticated',
  '{"provider":"email","providers":["email"]}'::jsonb,
  '{"phone_number":"+919900020042"}'::jsonb
);
INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at, role, aud, raw_app_meta_data, raw_user_meta_data)
VALUES (
  'ab3427a5-eae0-4a92-9fe3-fb0e316ff30a',
  'dummy_girl_44@auth.kurichiyar.com',
  crypt('password123', gen_salt('bf')),
  now(),
  now(),
  now(),
  'authenticated',
  'authenticated',
  '{"provider":"email","providers":["email"]}'::jsonb,
  '{"phone_number":"+919900020043"}'::jsonb
);
INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at, role, aud, raw_app_meta_data, raw_user_meta_data)
VALUES (
  'f82134a4-1391-4aa6-9575-07e5cc735e6e',
  'dummy_girl_45@auth.kurichiyar.com',
  crypt('password123', gen_salt('bf')),
  now(),
  now(),
  now(),
  'authenticated',
  'authenticated',
  '{"provider":"email","providers":["email"]}'::jsonb,
  '{"phone_number":"+919900020044"}'::jsonb
);
INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at, role, aud, raw_app_meta_data, raw_user_meta_data)
VALUES (
  '58988464-34f1-434e-accc-22f7b3b93c88',
  'dummy_girl_46@auth.kurichiyar.com',
  crypt('password123', gen_salt('bf')),
  now(),
  now(),
  now(),
  'authenticated',
  'authenticated',
  '{"provider":"email","providers":["email"]}'::jsonb,
  '{"phone_number":"+919900020045"}'::jsonb
);
INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at, role, aud, raw_app_meta_data, raw_user_meta_data)
VALUES (
  '3c1dd82e-0c5b-45bd-9746-54768f5bccd5',
  'dummy_girl_47@auth.kurichiyar.com',
  crypt('password123', gen_salt('bf')),
  now(),
  now(),
  now(),
  'authenticated',
  'authenticated',
  '{"provider":"email","providers":["email"]}'::jsonb,
  '{"phone_number":"+919900020046"}'::jsonb
);
INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at, role, aud, raw_app_meta_data, raw_user_meta_data)
VALUES (
  '9e8aa729-828a-40e0-b2c9-e86d04c2870d',
  'dummy_girl_48@auth.kurichiyar.com',
  crypt('password123', gen_salt('bf')),
  now(),
  now(),
  now(),
  'authenticated',
  'authenticated',
  '{"provider":"email","providers":["email"]}'::jsonb,
  '{"phone_number":"+919900020047"}'::jsonb
);
INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at, role, aud, raw_app_meta_data, raw_user_meta_data)
VALUES (
  'aa43d84d-01f0-4952-804b-d8aac6f25c07',
  'dummy_girl_49@auth.kurichiyar.com',
  crypt('password123', gen_salt('bf')),
  now(),
  now(),
  now(),
  'authenticated',
  'authenticated',
  '{"provider":"email","providers":["email"]}'::jsonb,
  '{"phone_number":"+919900020048"}'::jsonb
);
INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at, role, aud, raw_app_meta_data, raw_user_meta_data)
VALUES (
  '8ae0c4d1-c7ee-49fe-9a88-5918cbe67c39',
  'dummy_girl_50@auth.kurichiyar.com',
  crypt('password123', gen_salt('bf')),
  now(),
  now(),
  now(),
  'authenticated',
  'authenticated',
  '{"provider":"email","providers":["email"]}'::jsonb,
  '{"phone_number":"+919900020049"}'::jsonb
);
INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at, role, aud, raw_app_meta_data, raw_user_meta_data)
VALUES (
  '390ac9fe-dbd5-4165-a028-83c67d46e5ec',
  'dummy_girl_51@auth.kurichiyar.com',
  crypt('password123', gen_salt('bf')),
  now(),
  now(),
  now(),
  'authenticated',
  'authenticated',
  '{"provider":"email","providers":["email"]}'::jsonb,
  '{"phone_number":"+919900020050"}'::jsonb
);
INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at, role, aud, raw_app_meta_data, raw_user_meta_data)
VALUES (
  '9691535f-96cc-4878-80a0-c59ff41585e4',
  'dummy_girl_52@auth.kurichiyar.com',
  crypt('password123', gen_salt('bf')),
  now(),
  now(),
  now(),
  'authenticated',
  'authenticated',
  '{"provider":"email","providers":["email"]}'::jsonb,
  '{"phone_number":"+919900020051"}'::jsonb
);
INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at, role, aud, raw_app_meta_data, raw_user_meta_data)
VALUES (
  'ad1c626a-2717-4a1d-b219-955302d1845f',
  'dummy_girl_53@auth.kurichiyar.com',
  crypt('password123', gen_salt('bf')),
  now(),
  now(),
  now(),
  'authenticated',
  'authenticated',
  '{"provider":"email","providers":["email"]}'::jsonb,
  '{"phone_number":"+919900020052"}'::jsonb
);
INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at, role, aud, raw_app_meta_data, raw_user_meta_data)
VALUES (
  '34ee87e0-66bf-41e2-a2e5-451b6d347851',
  'dummy_girl_54@auth.kurichiyar.com',
  crypt('password123', gen_salt('bf')),
  now(),
  now(),
  now(),
  'authenticated',
  'authenticated',
  '{"provider":"email","providers":["email"]}'::jsonb,
  '{"phone_number":"+919900020053"}'::jsonb
);
INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at, role, aud, raw_app_meta_data, raw_user_meta_data)
VALUES (
  '44a9f10e-8d79-4935-b545-995af69cde90',
  'dummy_girl_55@auth.kurichiyar.com',
  crypt('password123', gen_salt('bf')),
  now(),
  now(),
  now(),
  'authenticated',
  'authenticated',
  '{"provider":"email","providers":["email"]}'::jsonb,
  '{"phone_number":"+919900020054"}'::jsonb
);
INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at, role, aud, raw_app_meta_data, raw_user_meta_data)
VALUES (
  'd48908f2-09a6-4ed9-83f5-0d063881c0ef',
  'dummy_girl_56@auth.kurichiyar.com',
  crypt('password123', gen_salt('bf')),
  now(),
  now(),
  now(),
  'authenticated',
  'authenticated',
  '{"provider":"email","providers":["email"]}'::jsonb,
  '{"phone_number":"+919900020055"}'::jsonb
);
INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at, role, aud, raw_app_meta_data, raw_user_meta_data)
VALUES (
  '37cfb1f5-4d8b-405b-ba48-28bbc7c0f329',
  'dummy_girl_57@auth.kurichiyar.com',
  crypt('password123', gen_salt('bf')),
  now(),
  now(),
  now(),
  'authenticated',
  'authenticated',
  '{"provider":"email","providers":["email"]}'::jsonb,
  '{"phone_number":"+919900020056"}'::jsonb
);

-- 4. Insert into public.profiles (if the table exists)
DO $$
BEGIN
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'profiles') THEN
        INSERT INTO public.profiles (id, full_name, gender, is_dummy, username, role, updated_at)
        VALUES ('ded869f2-c973-40b0-88ed-39de10b3835b', 'മാധവൻ പുത്തൻവീട്', 'male', true, 'dummy_boy_1', 'MEMBER', now()) ON CONFLICT (id) DO NOTHING;
        INSERT INTO public.profiles (id, full_name, gender, is_dummy, username, role, updated_at)
        VALUES ('61a600c4-c1c1-4c83-afaf-c6dedac22fab', 'ചന്ദ്രൻ വലിപ്പവീട്', 'male', true, 'dummy_boy_2', 'MEMBER', now()) ON CONFLICT (id) DO NOTHING;
        INSERT INTO public.profiles (id, full_name, gender, is_dummy, username, role, updated_at)
        VALUES ('e1e129c3-77b2-4def-9885-92b740f79411', 'ബാലൻ വയലിൽ', 'male', true, 'dummy_boy_3', 'MEMBER', now()) ON CONFLICT (id) DO NOTHING;
        INSERT INTO public.profiles (id, full_name, gender, is_dummy, username, role, updated_at)
        VALUES ('7037d077-0069-48bc-a9e3-d2e428e71f39', 'വിജയൻ വയലിൽ', 'male', true, 'dummy_boy_4', 'MEMBER', now()) ON CONFLICT (id) DO NOTHING;
        INSERT INTO public.profiles (id, full_name, gender, is_dummy, username, role, updated_at)
        VALUES ('ffd7f932-f02c-4090-97da-fb20e608de1c', 'രാമൻ മണൽവയൽ', 'male', true, 'dummy_boy_5', 'MEMBER', now()) ON CONFLICT (id) DO NOTHING;
        INSERT INTO public.profiles (id, full_name, gender, is_dummy, username, role, updated_at)
        VALUES ('5ab8b66b-2600-4880-bc32-029e8da85b9d', 'കേളൻ എടത്തറ', 'male', true, 'dummy_boy_6', 'MEMBER', now()) ON CONFLICT (id) DO NOTHING;
        INSERT INTO public.profiles (id, full_name, gender, is_dummy, username, role, updated_at)
        VALUES ('e01b6bde-0da3-4fa4-b3d3-77197b82c742', 'കൃഷ്ണൻ കിഴക്കേവീട്', 'male', true, 'dummy_boy_7', 'MEMBER', now()) ON CONFLICT (id) DO NOTHING;
        INSERT INTO public.profiles (id, full_name, gender, is_dummy, username, role, updated_at)
        VALUES ('b5da801a-07bc-4f61-9dde-160d854a1303', 'ഷാജി വയലിൽ', 'male', true, 'dummy_boy_8', 'MEMBER', now()) ON CONFLICT (id) DO NOTHING;
        INSERT INTO public.profiles (id, full_name, gender, is_dummy, username, role, updated_at)
        VALUES ('52d63c4d-3fa6-47af-aaa5-c8b609832a0a', 'ബാബു എടത്തറ', 'male', true, 'dummy_boy_9', 'MEMBER', now()) ON CONFLICT (id) DO NOTHING;
        INSERT INTO public.profiles (id, full_name, gender, is_dummy, username, role, updated_at)
        VALUES ('337ec196-e69c-48d5-8cec-27d04668353e', 'മധു കുനിയിൽ', 'male', true, 'dummy_boy_10', 'MEMBER', now()) ON CONFLICT (id) DO NOTHING;
        INSERT INTO public.profiles (id, full_name, gender, is_dummy, username, role, updated_at)
        VALUES ('17eec9df-5591-4ddc-8636-68b74b65d749', 'ഗിരീഷ് തറവാട്', 'male', true, 'dummy_boy_11', 'MEMBER', now()) ON CONFLICT (id) DO NOTHING;
        INSERT INTO public.profiles (id, full_name, gender, is_dummy, username, role, updated_at)
        VALUES ('7a1f0b2b-ee0c-43c3-9297-0484016530fe', 'രാജേഷ് കുന്നിൻമേൽ', 'male', true, 'dummy_boy_12', 'MEMBER', now()) ON CONFLICT (id) DO NOTHING;
        INSERT INTO public.profiles (id, full_name, gender, is_dummy, username, role, updated_at)
        VALUES ('88d65b16-9265-42fb-9948-e1485c2e3a07', 'സുരേഷ് കുനിയിൽ', 'male', true, 'dummy_boy_13', 'MEMBER', now()) ON CONFLICT (id) DO NOTHING;
        INSERT INTO public.profiles (id, full_name, gender, is_dummy, username, role, updated_at)
        VALUES ('34dd5e74-aa9d-4da9-82d5-ac3bd243e74d', 'അനീഷ് കുന്നിൻമേൽ', 'male', true, 'dummy_boy_14', 'MEMBER', now()) ON CONFLICT (id) DO NOTHING;
        INSERT INTO public.profiles (id, full_name, gender, is_dummy, username, role, updated_at)
        VALUES ('e55277b9-488c-4d61-84c3-c5f66d1a3bf8', 'വിനീത് എടത്തറ', 'male', true, 'dummy_boy_15', 'MEMBER', now()) ON CONFLICT (id) DO NOTHING;
        INSERT INTO public.profiles (id, full_name, gender, is_dummy, username, role, updated_at)
        VALUES ('5e1c0f1c-51df-47ea-ba7f-5abc5a25316b', 'സജീവ് മീത്തൽ', 'male', true, 'dummy_boy_16', 'MEMBER', now()) ON CONFLICT (id) DO NOTHING;
        INSERT INTO public.profiles (id, full_name, gender, is_dummy, username, role, updated_at)
        VALUES ('2ae5a186-74b5-4596-9c1d-b62b0391f858', 'മനു ചാലിൽ', 'male', true, 'dummy_boy_17', 'MEMBER', now()) ON CONFLICT (id) DO NOTHING;
        INSERT INTO public.profiles (id, full_name, gender, is_dummy, username, role, updated_at)
        VALUES ('0366736d-2b92-49b4-8458-69e9760bdd4a', 'വിപിൻ തറവാട്', 'male', true, 'dummy_boy_18', 'MEMBER', now()) ON CONFLICT (id) DO NOTHING;
        INSERT INTO public.profiles (id, full_name, gender, is_dummy, username, role, updated_at)
        VALUES ('7c55fee9-f518-4d56-b5ab-329ddcbebc88', 'ജിതിൻ പടിഞ്ഞാറേവീട്', 'male', true, 'dummy_boy_19', 'MEMBER', now()) ON CONFLICT (id) DO NOTHING;
        INSERT INTO public.profiles (id, full_name, gender, is_dummy, username, role, updated_at)
        VALUES ('c054482d-127b-4faf-ad9d-33fccc19386f', 'മിഥുൻ തറവാട്', 'male', true, 'dummy_boy_20', 'MEMBER', now()) ON CONFLICT (id) DO NOTHING;
        INSERT INTO public.profiles (id, full_name, gender, is_dummy, username, role, updated_at)
        VALUES ('26087f2d-11a6-4ebe-acd0-0227417a6d93', 'അഖിൽ പുത്തൻവീട്', 'male', true, 'dummy_boy_21', 'MEMBER', now()) ON CONFLICT (id) DO NOTHING;
        INSERT INTO public.profiles (id, full_name, gender, is_dummy, username, role, updated_at)
        VALUES ('0e81fb12-e35e-4823-a69d-70002b76c62e', 'രാഹുൽ എടക്കുടി', 'male', true, 'dummy_boy_22', 'MEMBER', now()) ON CONFLICT (id) DO NOTHING;
        INSERT INTO public.profiles (id, full_name, gender, is_dummy, username, role, updated_at)
        VALUES ('886f35ab-739c-4af5-b609-78d9c1981e1e', 'ഗോകുൽ തെക്കേവീട്', 'male', true, 'dummy_boy_23', 'MEMBER', now()) ON CONFLICT (id) DO NOTHING;
        INSERT INTO public.profiles (id, full_name, gender, is_dummy, username, role, updated_at)
        VALUES ('75f19889-7109-4923-a229-1a07f568923e', 'ഹരീഷ് വയലിൽ', 'male', true, 'dummy_boy_24', 'MEMBER', now()) ON CONFLICT (id) DO NOTHING;
        INSERT INTO public.profiles (id, full_name, gender, is_dummy, username, role, updated_at)
        VALUES ('09bd04bc-783b-47bf-878b-3bdceaeb0ffb', 'ശ്രീജിത്ത് എടത്തറ', 'male', true, 'dummy_boy_25', 'MEMBER', now()) ON CONFLICT (id) DO NOTHING;
        INSERT INTO public.profiles (id, full_name, gender, is_dummy, username, role, updated_at)
        VALUES ('64b51a70-1a48-4b5c-afea-20618bc456e5', 'ഉണ്ണികൃഷ്ണൻ പടിഞ്ഞാറേവീട്', 'male', true, 'dummy_boy_26', 'MEMBER', now()) ON CONFLICT (id) DO NOTHING;
        INSERT INTO public.profiles (id, full_name, gender, is_dummy, username, role, updated_at)
        VALUES ('cdd0b5f8-2dc3-4238-943c-67c82352f7b1', 'മണികണ്ഠൻ വലിപ്പവീട്', 'male', true, 'dummy_boy_27', 'MEMBER', now()) ON CONFLICT (id) DO NOTHING;
        INSERT INTO public.profiles (id, full_name, gender, is_dummy, username, role, updated_at)
        VALUES ('b31390c7-0647-42af-8daf-6e6ba9619ac4', 'പ്രദീപ് പടിഞ്ഞാറേവീട്', 'male', true, 'dummy_boy_28', 'MEMBER', now()) ON CONFLICT (id) DO NOTHING;
        INSERT INTO public.profiles (id, full_name, gender, is_dummy, username, role, updated_at)
        VALUES ('84d22bdb-9620-4d88-b88c-b2e9e540d9df', 'പ്രമോദ് പുത്തൻവീട്', 'male', true, 'dummy_boy_29', 'MEMBER', now()) ON CONFLICT (id) DO NOTHING;
        INSERT INTO public.profiles (id, full_name, gender, is_dummy, username, role, updated_at)
        VALUES ('728538c0-b300-41ed-8113-6582318e19b6', 'സന്തോഷ് വടക്കേവീട്', 'male', true, 'dummy_boy_30', 'MEMBER', now()) ON CONFLICT (id) DO NOTHING;
        INSERT INTO public.profiles (id, full_name, gender, is_dummy, username, role, updated_at)
        VALUES ('45a91ff8-db5f-41a7-8786-8adf7b6a68a7', 'ഹരിദാസൻ കുനിയിൽ', 'male', true, 'dummy_boy_31', 'MEMBER', now()) ON CONFLICT (id) DO NOTHING;
        INSERT INTO public.profiles (id, full_name, gender, is_dummy, username, role, updated_at)
        VALUES ('91627f6b-3ad4-4817-a95a-5939eb1b7de9', 'സുകുമാരൻ പടിഞ്ഞാറേവീട്', 'male', true, 'dummy_boy_32', 'MEMBER', now()) ON CONFLICT (id) DO NOTHING;
        INSERT INTO public.profiles (id, full_name, gender, is_dummy, username, role, updated_at)
        VALUES ('8b50311a-d2b9-4ca6-907b-8f964bc7e841', 'ഭാസ്കരൻ തെക്കേവീട്', 'male', true, 'dummy_boy_33', 'MEMBER', now()) ON CONFLICT (id) DO NOTHING;
        INSERT INTO public.profiles (id, full_name, gender, is_dummy, username, role, updated_at)
        VALUES ('4548b157-2440-44af-9aee-aca67ded68f5', 'വേണുഗോപാൽ താഴെവീട്', 'male', true, 'dummy_boy_34', 'MEMBER', now()) ON CONFLICT (id) DO NOTHING;
        INSERT INTO public.profiles (id, full_name, gender, is_dummy, username, role, updated_at)
        VALUES ('79c5bb3e-d972-472f-8adb-c75b9f2007f6', 'ഗംഗാധരൻ കുനിയിൽ', 'male', true, 'dummy_boy_35', 'MEMBER', now()) ON CONFLICT (id) DO NOTHING;
        INSERT INTO public.profiles (id, full_name, gender, is_dummy, username, role, updated_at)
        VALUES ('24f1fc20-aae9-4454-9baa-baefeb7950e3', 'രാധാകൃഷ്ണൻ ഓലിക്കൽ', 'male', true, 'dummy_boy_36', 'MEMBER', now()) ON CONFLICT (id) DO NOTHING;
        INSERT INTO public.profiles (id, full_name, gender, is_dummy, username, role, updated_at)
        VALUES ('68f34e9e-00e4-4fc7-8556-22f83fd2e5a8', 'മോഹൻദാസ് കുനിയിൽ', 'male', true, 'dummy_boy_37', 'MEMBER', now()) ON CONFLICT (id) DO NOTHING;
        INSERT INTO public.profiles (id, full_name, gender, is_dummy, username, role, updated_at)
        VALUES ('27932b2f-ac26-4e1a-a995-0c419e881797', 'പ്രകാശൻ വടക്കേവീട്', 'male', true, 'dummy_boy_38', 'MEMBER', now()) ON CONFLICT (id) DO NOTHING;
        INSERT INTO public.profiles (id, full_name, gender, is_dummy, username, role, updated_at)
        VALUES ('20a91055-01e1-463c-9d79-469a5885feca', 'ജയരാജൻ മീത്തൽ', 'male', true, 'dummy_boy_39', 'MEMBER', now()) ON CONFLICT (id) DO NOTHING;
        INSERT INTO public.profiles (id, full_name, gender, is_dummy, username, role, updated_at)
        VALUES ('5046e7de-e1aa-436b-8c9a-7f059f045289', 'രാജീവൻ എടത്തറ', 'male', true, 'dummy_boy_40', 'MEMBER', now()) ON CONFLICT (id) DO NOTHING;
        INSERT INTO public.profiles (id, full_name, gender, is_dummy, username, role, updated_at)
        VALUES ('7575f9f3-2488-4045-bf0e-b0050c32c9ee', 'വിനോദ് പടിഞ്ഞാറേവീട്', 'male', true, 'dummy_boy_41', 'MEMBER', now()) ON CONFLICT (id) DO NOTHING;
        INSERT INTO public.profiles (id, full_name, gender, is_dummy, username, role, updated_at)
        VALUES ('26ffe558-540c-4e5c-b6cf-d9fdc5e4f237', 'ജയചന്ദ്രൻ കോട്ടയിൽ', 'male', true, 'dummy_boy_42', 'MEMBER', now()) ON CONFLICT (id) DO NOTHING;
        INSERT INTO public.profiles (id, full_name, gender, is_dummy, username, role, updated_at)
        VALUES ('423797cb-ef2b-4c54-ba84-326dc9a95781', 'സുനിൽ തെക്കേവീട്', 'male', true, 'dummy_boy_43', 'MEMBER', now()) ON CONFLICT (id) DO NOTHING;
        INSERT INTO public.profiles (id, full_name, gender, is_dummy, username, role, updated_at)
        VALUES ('4c801080-2806-4248-9aee-bc00d54cf147', 'അനിലി കുനിയിൽ', 'male', true, 'dummy_boy_44', 'MEMBER', now()) ON CONFLICT (id) DO NOTHING;
        INSERT INTO public.profiles (id, full_name, gender, is_dummy, username, role, updated_at)
        VALUES ('f485ffca-f90e-4738-b94e-8795e0671f4e', 'സതീശൻ വലിപ്പവീട്', 'male', true, 'dummy_boy_45', 'MEMBER', now()) ON CONFLICT (id) DO NOTHING;
        INSERT INTO public.profiles (id, full_name, gender, is_dummy, username, role, updated_at)
        VALUES ('786381e7-38da-4ff2-bd01-d3c11419750f', 'സുധീഷ് കുനിയിൽ', 'male', true, 'dummy_boy_46', 'MEMBER', now()) ON CONFLICT (id) DO NOTHING;
        INSERT INTO public.profiles (id, full_name, gender, is_dummy, username, role, updated_at)
        VALUES ('8c3411df-f09e-4ce8-9271-a8d750ccb4fd', 'മഹേഷ് കുനിയിൽ', 'male', true, 'dummy_boy_47', 'MEMBER', now()) ON CONFLICT (id) DO NOTHING;
        INSERT INTO public.profiles (id, full_name, gender, is_dummy, username, role, updated_at)
        VALUES ('973fb2b9-2d66-494c-9b26-5a6aefaaf200', 'അഭിലാഷ് വലിപ്പവീട്', 'male', true, 'dummy_boy_48', 'MEMBER', now()) ON CONFLICT (id) DO NOTHING;
        INSERT INTO public.profiles (id, full_name, gender, is_dummy, username, role, updated_at)
        VALUES ('7a79327c-f145-41c5-84e4-fbf1614b52a8', 'കിരൺ പുത്തൻവീട്', 'male', true, 'dummy_boy_49', 'MEMBER', now()) ON CONFLICT (id) DO NOTHING;
        INSERT INTO public.profiles (id, full_name, gender, is_dummy, username, role, updated_at)
        VALUES ('dbb968cb-19ca-4ab7-af40-3756394ead53', 'സനൂപ് കുന്നിൻമേൽ', 'male', true, 'dummy_boy_50', 'MEMBER', now()) ON CONFLICT (id) DO NOTHING;
        INSERT INTO public.profiles (id, full_name, gender, is_dummy, username, role, updated_at)
        VALUES ('4c92a8e3-faf0-4eb8-b115-e62b763dcc3f', 'വിഷ്ണു എടക്കുടി', 'male', true, 'dummy_boy_51', 'MEMBER', now()) ON CONFLICT (id) DO NOTHING;
        INSERT INTO public.profiles (id, full_name, gender, is_dummy, username, role, updated_at)
        VALUES ('aa2d15dc-5de5-4848-af2d-c3f514d208f8', 'അർജുൻ പാലക്കൽ', 'male', true, 'dummy_boy_52', 'MEMBER', now()) ON CONFLICT (id) DO NOTHING;
        INSERT INTO public.profiles (id, full_name, gender, is_dummy, username, role, updated_at)
        VALUES ('adcdca3b-a898-4d31-a209-58537452e477', 'സാരംഗ് മീത്തൽ', 'male', true, 'dummy_boy_53', 'MEMBER', now()) ON CONFLICT (id) DO NOTHING;
        INSERT INTO public.profiles (id, full_name, gender, is_dummy, username, role, updated_at)
        VALUES ('de157d2e-a1c8-4f72-b071-562e2ff3bff7', 'ജിനേഷ് ഇല്ലം', 'male', true, 'dummy_boy_54', 'MEMBER', now()) ON CONFLICT (id) DO NOTHING;
        INSERT INTO public.profiles (id, full_name, gender, is_dummy, username, role, updated_at)
        VALUES ('bde1992b-1095-406b-918a-12c03cc7a8e9', 'വിജിത്ത് ഓലിക്കൽ', 'male', true, 'dummy_boy_55', 'MEMBER', now()) ON CONFLICT (id) DO NOTHING;
        INSERT INTO public.profiles (id, full_name, gender, is_dummy, username, role, updated_at)
        VALUES ('e9bb5c03-0087-4fa0-8c3d-07aedd0627e5', 'സായൂജ് തെക്കേവീട്', 'male', true, 'dummy_boy_56', 'MEMBER', now()) ON CONFLICT (id) DO NOTHING;
        INSERT INTO public.profiles (id, full_name, gender, is_dummy, username, role, updated_at)
        VALUES ('32c91873-a455-43d1-982a-199faf061814', 'അഭിനന്ദ് വയലിൽ', 'male', true, 'dummy_boy_57', 'MEMBER', now()) ON CONFLICT (id) DO NOTHING;
        INSERT INTO public.profiles (id, full_name, gender, is_dummy, username, role, updated_at)
        VALUES ('e529b89b-54ee-4337-bb48-36446ff9c027', 'രാധ വടക്കേവീട്', 'female', true, 'dummy_girl_1', 'MEMBER', now()) ON CONFLICT (id) DO NOTHING;
        INSERT INTO public.profiles (id, full_name, gender, is_dummy, username, role, updated_at)
        VALUES ('64dd6f70-e0c7-4996-8ef1-41bddbece35a', 'അമ്മിണി മീത്തൽ', 'female', true, 'dummy_girl_2', 'MEMBER', now()) ON CONFLICT (id) DO NOTHING;
        INSERT INTO public.profiles (id, full_name, gender, is_dummy, username, role, updated_at)
        VALUES ('8e4fe080-e41e-4580-847c-28bf797b0b40', 'കല്യാണി തറവാട്', 'female', true, 'dummy_girl_3', 'MEMBER', now()) ON CONFLICT (id) DO NOTHING;
        INSERT INTO public.profiles (id, full_name, gender, is_dummy, username, role, updated_at)
        VALUES ('ed310172-f1cd-4ab5-aa99-bd5d1581aec3', 'ലക്ഷ്മി മണൽവയൽ', 'female', true, 'dummy_girl_4', 'MEMBER', now()) ON CONFLICT (id) DO NOTHING;
        INSERT INTO public.profiles (id, full_name, gender, is_dummy, username, role, updated_at)
        VALUES ('58bd47ff-b05c-484a-a854-8804b7361d4f', 'പാർവ്വതി എടക്കുടി', 'female', true, 'dummy_girl_5', 'MEMBER', now()) ON CONFLICT (id) DO NOTHING;
        INSERT INTO public.profiles (id, full_name, gender, is_dummy, username, role, updated_at)
        VALUES ('468fcbb2-f414-4b46-80d1-e2755a977e1c', 'ദേവിക തറവാട്', 'female', true, 'dummy_girl_6', 'MEMBER', now()) ON CONFLICT (id) DO NOTHING;
        INSERT INTO public.profiles (id, full_name, gender, is_dummy, username, role, updated_at)
        VALUES ('d42e979a-fbf4-4da5-b625-b05b3e0f2da5', 'അഞ്ജന വടക്കേവീട്', 'female', true, 'dummy_girl_7', 'MEMBER', now()) ON CONFLICT (id) DO NOTHING;
        INSERT INTO public.profiles (id, full_name, gender, is_dummy, username, role, updated_at)
        VALUES ('7857ca13-6dfc-4204-80e4-a22a87f6b83b', 'ആതിര മീത്തൽ', 'female', true, 'dummy_girl_8', 'MEMBER', now()) ON CONFLICT (id) DO NOTHING;
        INSERT INTO public.profiles (id, full_name, gender, is_dummy, username, role, updated_at)
        VALUES ('b45928d8-e863-4c47-a94b-cbb4f90c03b6', 'രമ്യ പുത്തൻവീട്', 'female', true, 'dummy_girl_9', 'MEMBER', now()) ON CONFLICT (id) DO NOTHING;
        INSERT INTO public.profiles (id, full_name, gender, is_dummy, username, role, updated_at)
        VALUES ('752359a2-657a-4fda-95f0-36ecebf5a479', 'കാവ്യ കുന്നിൻമേൽ', 'female', true, 'dummy_girl_10', 'MEMBER', now()) ON CONFLICT (id) DO NOTHING;
        INSERT INTO public.profiles (id, full_name, gender, is_dummy, username, role, updated_at)
        VALUES ('530a18b4-b0f5-4355-9b26-41a4bd8da96d', 'സരിത കിഴക്കേവീട്', 'female', true, 'dummy_girl_11', 'MEMBER', now()) ON CONFLICT (id) DO NOTHING;
        INSERT INTO public.profiles (id, full_name, gender, is_dummy, username, role, updated_at)
        VALUES ('95fa5d88-dd76-4828-a384-e1bb3ec3f048', 'സുനിത ചാലിൽ', 'female', true, 'dummy_girl_12', 'MEMBER', now()) ON CONFLICT (id) DO NOTHING;
        INSERT INTO public.profiles (id, full_name, gender, is_dummy, username, role, updated_at)
        VALUES ('2374d0eb-3db6-4cda-8b1a-7b1b22b839b5', 'ബിന്ദു എടക്കുടി', 'female', true, 'dummy_girl_13', 'MEMBER', now()) ON CONFLICT (id) DO NOTHING;
        INSERT INTO public.profiles (id, full_name, gender, is_dummy, username, role, updated_at)
        VALUES ('bee7589d-d3c2-4e5b-ab53-9f49c230b822', 'സിന്ധു ഓലിക്കൽ', 'female', true, 'dummy_girl_14', 'MEMBER', now()) ON CONFLICT (id) DO NOTHING;
        INSERT INTO public.profiles (id, full_name, gender, is_dummy, username, role, updated_at)
        VALUES ('3b283d73-9bc7-4798-a8eb-2e547cb09c10', 'മിനി മണൽവയൽ', 'female', true, 'dummy_girl_15', 'MEMBER', now()) ON CONFLICT (id) DO NOTHING;
        INSERT INTO public.profiles (id, full_name, gender, is_dummy, username, role, updated_at)
        VALUES ('0509c136-d9b2-4860-9ac1-68d0bc5ed62c', 'ഷീല പടിഞ്ഞാറേവീട്', 'female', true, 'dummy_girl_16', 'MEMBER', now()) ON CONFLICT (id) DO NOTHING;
        INSERT INTO public.profiles (id, full_name, gender, is_dummy, username, role, updated_at)
        VALUES ('87596c56-2865-4c83-a4c7-805c567fee49', 'ഗീത വലിപ്പവീട്', 'female', true, 'dummy_girl_17', 'MEMBER', now()) ON CONFLICT (id) DO NOTHING;
        INSERT INTO public.profiles (id, full_name, gender, is_dummy, username, role, updated_at)
        VALUES ('4563119b-6107-4d79-a603-4b10797176d7', 'സൗമ്യ പുത്തൻവീട്', 'female', true, 'dummy_girl_18', 'MEMBER', now()) ON CONFLICT (id) DO NOTHING;
        INSERT INTO public.profiles (id, full_name, gender, is_dummy, username, role, updated_at)
        VALUES ('a377297a-61eb-4b21-befd-929271047b7c', 'ധന്യ കുന്നിൻമേൽ', 'female', true, 'dummy_girl_19', 'MEMBER', now()) ON CONFLICT (id) DO NOTHING;
        INSERT INTO public.profiles (id, full_name, gender, is_dummy, username, role, updated_at)
        VALUES ('3d930cd2-cd35-4bc6-8526-0b75ad7ad0a9', 'രശ്മി എടക്കുടി', 'female', true, 'dummy_girl_20', 'MEMBER', now()) ON CONFLICT (id) DO NOTHING;
        INSERT INTO public.profiles (id, full_name, gender, is_dummy, username, role, updated_at)
        VALUES ('7fb223c1-3290-4f80-ad1a-8baacc144388', 'ദിവ്യ എടക്കുടി', 'female', true, 'dummy_girl_21', 'MEMBER', now()) ON CONFLICT (id) DO NOTHING;
        INSERT INTO public.profiles (id, full_name, gender, is_dummy, username, role, updated_at)
        VALUES ('1eec5a08-3629-4612-8329-dd20e23c7ad3', 'സജിത വയലിൽ', 'female', true, 'dummy_girl_22', 'MEMBER', now()) ON CONFLICT (id) DO NOTHING;
        INSERT INTO public.profiles (id, full_name, gender, is_dummy, username, role, updated_at)
        VALUES ('22ee5a30-390c-4e54-a041-316072ad310d', 'ഷൈനി കോട്ടയിൽ', 'female', true, 'dummy_girl_23', 'MEMBER', now()) ON CONFLICT (id) DO NOTHING;
        INSERT INTO public.profiles (id, full_name, gender, is_dummy, username, role, updated_at)
        VALUES ('8334d4a7-abba-4ef8-ad5f-138ffbd9987a', 'അനുപമ പടിഞ്ഞാറേവീട്', 'female', true, 'dummy_girl_24', 'MEMBER', now()) ON CONFLICT (id) DO NOTHING;
        INSERT INTO public.profiles (id, full_name, gender, is_dummy, username, role, updated_at)
        VALUES ('d85df924-4849-499b-81c5-424087e7518b', 'ആര്യ തെക്കേവീട്', 'female', true, 'dummy_girl_25', 'MEMBER', now()) ON CONFLICT (id) DO NOTHING;
        INSERT INTO public.profiles (id, full_name, gender, is_dummy, username, role, updated_at)
        VALUES ('24ae5f4f-89ae-4305-a521-48a78eb4c6b4', 'രേഷ്മ വയലിൽ', 'female', true, 'dummy_girl_26', 'MEMBER', now()) ON CONFLICT (id) DO NOTHING;
        INSERT INTO public.profiles (id, full_name, gender, is_dummy, username, role, updated_at)
        VALUES ('909c4ee4-a206-4bf1-a1a7-2f7ac5233d4a', 'ജിഷ ഇല്ലം', 'female', true, 'dummy_girl_27', 'MEMBER', now()) ON CONFLICT (id) DO NOTHING;
        INSERT INTO public.profiles (id, full_name, gender, is_dummy, username, role, updated_at)
        VALUES ('211ba6b6-0b87-4eee-ad7f-57aa261f3131', 'നിഷ എടക്കുടി', 'female', true, 'dummy_girl_28', 'MEMBER', now()) ON CONFLICT (id) DO NOTHING;
        INSERT INTO public.profiles (id, full_name, gender, is_dummy, username, role, updated_at)
        VALUES ('b1d519bd-b83d-4596-9174-cc99dcf0a30d', 'സ്മിത എടത്തറ', 'female', true, 'dummy_girl_29', 'MEMBER', now()) ON CONFLICT (id) DO NOTHING;
        INSERT INTO public.profiles (id, full_name, gender, is_dummy, username, role, updated_at)
        VALUES ('d1363d34-3167-41a3-8311-2ee6cf4f0c75', 'അഖില കുന്നിൻമേൽ', 'female', true, 'dummy_girl_30', 'MEMBER', now()) ON CONFLICT (id) DO NOTHING;
        INSERT INTO public.profiles (id, full_name, gender, is_dummy, username, role, updated_at)
        VALUES ('29c3316b-b97c-46a5-a9a8-ed281b93c5e5', 'കാർത്തിക വടക്കേവീട്', 'female', true, 'dummy_girl_31', 'MEMBER', now()) ON CONFLICT (id) DO NOTHING;
        INSERT INTO public.profiles (id, full_name, gender, is_dummy, username, role, updated_at)
        VALUES ('870c5838-46b8-4266-b0df-848c45f9ce1a', 'കീർത്തന ഓലിക്കൽ', 'female', true, 'dummy_girl_32', 'MEMBER', now()) ON CONFLICT (id) DO NOTHING;
        INSERT INTO public.profiles (id, full_name, gender, is_dummy, username, role, updated_at)
        VALUES ('ae802044-3343-4b83-acb8-40d0ccd97fd5', 'ഗ്രീഷ്മ വടക്കേവീട്', 'female', true, 'dummy_girl_33', 'MEMBER', now()) ON CONFLICT (id) DO NOTHING;
        INSERT INTO public.profiles (id, full_name, gender, is_dummy, username, role, updated_at)
        VALUES ('aa5b22bb-2d0a-4b7f-b01f-473868c7cd4f', 'അനഘ തെക്കേവീട്', 'female', true, 'dummy_girl_34', 'MEMBER', now()) ON CONFLICT (id) DO NOTHING;
        INSERT INTO public.profiles (id, full_name, gender, is_dummy, username, role, updated_at)
        VALUES ('18d1fab1-9fa9-4094-a93d-2fa1c70a7f50', 'അഞ്ജലി ചാലിൽ', 'female', true, 'dummy_girl_35', 'MEMBER', now()) ON CONFLICT (id) DO NOTHING;
        INSERT INTO public.profiles (id, full_name, gender, is_dummy, username, role, updated_at)
        VALUES ('6816c332-a78b-4146-b77c-74118e69f2e0', 'ശ്രുതി ഇല്ലം', 'female', true, 'dummy_girl_36', 'MEMBER', now()) ON CONFLICT (id) DO NOTHING;
        INSERT INTO public.profiles (id, full_name, gender, is_dummy, username, role, updated_at)
        VALUES ('38921965-6d1c-4cc4-9fef-6e6cf27f663b', 'ശില്പ എടത്തറ', 'female', true, 'dummy_girl_37', 'MEMBER', now()) ON CONFLICT (id) DO NOTHING;
        INSERT INTO public.profiles (id, full_name, gender, is_dummy, username, role, updated_at)
        VALUES ('fa75522f-c756-42ff-a7d8-184618c163dc', 'ശരണ്യ കിഴക്കേവീട്', 'female', true, 'dummy_girl_38', 'MEMBER', now()) ON CONFLICT (id) DO NOTHING;
        INSERT INTO public.profiles (id, full_name, gender, is_dummy, username, role, updated_at)
        VALUES ('2ded6bc9-5d55-4a6c-9ce4-77b166acd5c0', 'പ്രിയങ്ക എടത്തറ', 'female', true, 'dummy_girl_39', 'MEMBER', now()) ON CONFLICT (id) DO NOTHING;
        INSERT INTO public.profiles (id, full_name, gender, is_dummy, username, role, updated_at)
        VALUES ('1f89b8a9-8b2d-45a6-b346-5dd129b9e0ee', 'അർച്ചന മീത്തൽ', 'female', true, 'dummy_girl_40', 'MEMBER', now()) ON CONFLICT (id) DO NOTHING;
        INSERT INTO public.profiles (id, full_name, gender, is_dummy, username, role, updated_at)
        VALUES ('1ca37662-a75f-48b9-b0bb-aa67d689e736', 'വിദ്യ ചാലിൽ', 'female', true, 'dummy_girl_41', 'MEMBER', now()) ON CONFLICT (id) DO NOTHING;
        INSERT INTO public.profiles (id, full_name, gender, is_dummy, username, role, updated_at)
        VALUES ('09afadcf-bd24-4275-9816-aa0b70c6ca59', 'പ്രസീത വയലിൽ', 'female', true, 'dummy_girl_42', 'MEMBER', now()) ON CONFLICT (id) DO NOTHING;
        INSERT INTO public.profiles (id, full_name, gender, is_dummy, username, role, updated_at)
        VALUES ('1068e893-390c-4447-a2d6-cc58866b4610', 'ശ്രീജ പുത്തൻവീട്', 'female', true, 'dummy_girl_43', 'MEMBER', now()) ON CONFLICT (id) DO NOTHING;
        INSERT INTO public.profiles (id, full_name, gender, is_dummy, username, role, updated_at)
        VALUES ('ab3427a5-eae0-4a92-9fe3-fb0e316ff30a', 'സിനി പുത്തൻവീട്', 'female', true, 'dummy_girl_44', 'MEMBER', now()) ON CONFLICT (id) DO NOTHING;
        INSERT INTO public.profiles (id, full_name, gender, is_dummy, username, role, updated_at)
        VALUES ('f82134a4-1391-4aa6-9575-07e5cc735e6e', 'ഷീബ മീത്തൽ', 'female', true, 'dummy_girl_45', 'MEMBER', now()) ON CONFLICT (id) DO NOTHING;
        INSERT INTO public.profiles (id, full_name, gender, is_dummy, username, role, updated_at)
        VALUES ('58988464-34f1-434e-accc-22f7b3b93c88', 'മായ മീത്തൽ', 'female', true, 'dummy_girl_46', 'MEMBER', now()) ON CONFLICT (id) DO NOTHING;
        INSERT INTO public.profiles (id, full_name, gender, is_dummy, username, role, updated_at)
        VALUES ('3c1dd82e-0c5b-45bd-9746-54768f5bccd5', 'വിജിത വടക്കേവീട്', 'female', true, 'dummy_girl_47', 'MEMBER', now()) ON CONFLICT (id) DO NOTHING;
        INSERT INTO public.profiles (id, full_name, gender, is_dummy, username, role, updated_at)
        VALUES ('9e8aa729-828a-40e0-b2c9-e86d04c2870d', 'അംബിക പാലക്കൽ', 'female', true, 'dummy_girl_48', 'MEMBER', now()) ON CONFLICT (id) DO NOTHING;
        INSERT INTO public.profiles (id, full_name, gender, is_dummy, username, role, updated_at)
        VALUES ('aa43d84d-01f0-4952-804b-d8aac6f25c07', 'യമുന ഇല്ലം', 'female', true, 'dummy_girl_49', 'MEMBER', now()) ON CONFLICT (id) DO NOTHING;
        INSERT INTO public.profiles (id, full_name, gender, is_dummy, username, role, updated_at)
        VALUES ('8ae0c4d1-c7ee-49fe-9a88-5918cbe67c39', 'ശോഭന എടക്കുടി', 'female', true, 'dummy_girl_50', 'MEMBER', now()) ON CONFLICT (id) DO NOTHING;
        INSERT INTO public.profiles (id, full_name, gender, is_dummy, username, role, updated_at)
        VALUES ('390ac9fe-dbd5-4165-a028-83c67d46e5ec', 'ഗിരിജ തറവാട്', 'female', true, 'dummy_girl_51', 'MEMBER', now()) ON CONFLICT (id) DO NOTHING;
        INSERT INTO public.profiles (id, full_name, gender, is_dummy, username, role, updated_at)
        VALUES ('9691535f-96cc-4878-80a0-c59ff41585e4', 'മഞ്ജു പടിഞ്ഞാറേവീട്', 'female', true, 'dummy_girl_52', 'MEMBER', now()) ON CONFLICT (id) DO NOTHING;
        INSERT INTO public.profiles (id, full_name, gender, is_dummy, username, role, updated_at)
        VALUES ('ad1c626a-2717-4a1d-b219-955302d1845f', 'ലേഖ എടക്കുടി', 'female', true, 'dummy_girl_53', 'MEMBER', now()) ON CONFLICT (id) DO NOTHING;
        INSERT INTO public.profiles (id, full_name, gender, is_dummy, username, role, updated_at)
        VALUES ('34ee87e0-66bf-41e2-a2e5-451b6d347851', 'സുജ മീത്തൽ', 'female', true, 'dummy_girl_54', 'MEMBER', now()) ON CONFLICT (id) DO NOTHING;
        INSERT INTO public.profiles (id, full_name, gender, is_dummy, username, role, updated_at)
        VALUES ('44a9f10e-8d79-4935-b545-995af69cde90', 'രജനി പുത്തൻവീട്', 'female', true, 'dummy_girl_55', 'MEMBER', now()) ON CONFLICT (id) DO NOTHING;
        INSERT INTO public.profiles (id, full_name, gender, is_dummy, username, role, updated_at)
        VALUES ('d48908f2-09a6-4ed9-83f5-0d063881c0ef', 'സുമ ഓലിക്കൽ', 'female', true, 'dummy_girl_56', 'MEMBER', now()) ON CONFLICT (id) DO NOTHING;
        INSERT INTO public.profiles (id, full_name, gender, is_dummy, username, role, updated_at)
        VALUES ('37cfb1f5-4d8b-405b-ba48-28bbc7c0f329', 'ഷീന തെക്കേവീട്', 'female', true, 'dummy_girl_57', 'MEMBER', now()) ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

-- 5. Insert into public.kurichiyar_profiles
INSERT INTO public.kurichiyar_profiles (
  id, created_at, updated_at, phone, email, full_name, name, age, gender, dob, photo_url,
  father_tharavadu, mother_tharavadu, father_clan_id, mother_clan_id, district, state,
  about_me, education_level, occupation, income, registration_status, status, approval_status,
  account_status, subscription_tier, is_dummy, photo_approved, is_banned, is_agent, is_out_of_caste, report_count,
  house_name, blood_group, height_cm, weight_kg, taluk, post_office, pincode, family_details, hobbies
) VALUES (
  'ded869f2-c973-40b0-88ed-39de10b3835b', now(), now(), '+919900010000', 'dummy_boy_1@auth.kurichiyar.com', 'മാധവൻ പുത്തൻവീട്', 'മാധവൻ പുത്തൻവീട്', 24, 'male', '2002-04-22', 'https://noidreeslytswkmsnmcn.supabase.co/storage/v1/object/public/user_documents/profile_photos/placeholder_male.png',
  'കുന്നംകൊലൻ (ചേരിമ്മൽ)', 'പടനി (കുഴികണ്ടം)', 13, 53, 'കോഴിക്കോട്', 'Kerala',
  'സർക്കാർ ജോലി ചെയ്യുന്നു. മാതാപിതാക്കളോടൊപ്പം വയനാട്ടിലാണ് താമസം. കുടുംബസ്നേഹമുള്ള ഒരു പങ്കാളിയെ തേടുന്നു.', 'എം.എസ്.സി. ബിരുദം', 'സർക്കാർ ജീവനക്കാരൻ', '4 ലക്ഷം രൂപ', 'live', 'APPROVED', 'Approved',
  'adminReview', 'Free', true, true, false, false, false, 0,
  'പുത്തൻവീട്', 'AB+', 178, 60, 'കൊയിലാണ്ടി', 'ബാലുശ്ശേരി', '673222', 'മാതാവും പിതാവും അടങ്ങുന്ന സന്തുഷ്ട കുടുംബം.', '["വായിക്കുക", "കൃഷി ചെയ്യുക", "യാത്ര ചെയ്യുക"]'
);
INSERT INTO public.kurichiyar_profiles (
  id, created_at, updated_at, phone, email, full_name, name, age, gender, dob, photo_url,
  father_tharavadu, mother_tharavadu, father_clan_id, mother_clan_id, district, state,
  about_me, education_level, occupation, income, registration_status, status, approval_status,
  account_status, subscription_tier, is_dummy, photo_approved, is_banned, is_agent, is_out_of_caste, report_count,
  house_name, blood_group, height_cm, weight_kg, taluk, post_office, pincode, family_details, hobbies
) VALUES (
  '61a600c4-c1c1-4c83-afaf-c6dedac22fab', now(), now(), '+919900010001', 'dummy_boy_2@auth.kurichiyar.com', 'ചന്ദ്രൻ വലിപ്പവീട്', 'ചന്ദ്രൻ വലിപ്പവീട്', 30, 'male', '1995-08-18', 'https://noidreeslytswkmsnmcn.supabase.co/storage/v1/object/public/user_documents/profile_photos/placeholder_male.png',
  'പാടിയേരി (ഞാരലോട്ട്)', 'ഇടുണി (കിഴക്കുംപാട്ട് - ഇടുണി)', 41, 44, 'വയനാട്', 'Kerala',
  'സർക്കാർ ജോലി ചെയ്യുന്നു. മാതാപിതാക്കളോടൊപ്പം വയനാട്ടിലാണ് താമസം. കുടുംബസ്നേഹമുള്ള ഒരു പങ്കാളിയെ തേടുന്നു.', 'ബി.കോം ബിരുദം', 'софтവെയർ എഞ്ചിനീയർ', '4 ലക്ഷം രൂപ', 'live', 'APPROVED', 'Approved',
  'adminReview', 'Free', true, true, false, false, false, 0,
  'വലിപ്പവീട്', 'AB+', 176, 69, 'സുൽത്താൻ ബത്തേരി', 'അമ്പലക്കുന്ന്', '673620', 'മാതാവും പിതാവും അടങ്ങുന്ന സന്തുഷ്ട കുടുംബം.', '["വായിക്കുക", "കൃഷി ചെയ്യുക", "യാത്ര ചെയ്യുക"]'
);
INSERT INTO public.kurichiyar_profiles (
  id, created_at, updated_at, phone, email, full_name, name, age, gender, dob, photo_url,
  father_tharavadu, mother_tharavadu, father_clan_id, mother_clan_id, district, state,
  about_me, education_level, occupation, income, registration_status, status, approval_status,
  account_status, subscription_tier, is_dummy, photo_approved, is_banned, is_agent, is_out_of_caste, report_count,
  house_name, blood_group, height_cm, weight_kg, taluk, post_office, pincode, family_details, hobbies
) VALUES (
  'e1e129c3-77b2-4def-9885-92b740f79411', now(), now(), '+919900010002', 'dummy_boy_3@auth.kurichiyar.com', 'ബാലൻ വയലിൽ', 'ബാലൻ വയലിൽ', 33, 'male', '1993-05-14', 'https://noidreeslytswkmsnmcn.supabase.co/storage/v1/object/public/user_documents/profile_photos/placeholder_male.png',
  'അതിരും കൊലൻ (പঞ্চേരി)', 'മങ്ങാനി പുത്തൂർ (മങ്ങാനി)', 37, 22, 'കോഴിക്കോട്', 'Kerala',
  'സർക്കാർ ജോലി ചെയ്യുന്നു. മാതാപിതാക്കളോടൊപ്പം വയനാട്ടിലാണ് താമസം. കുടുംബസ്നേഹമുള്ള ഒരു പങ്കാളിയെ തേടുന്നു.', 'എസ്.എസ്.എൽ.സി', 'തയ്യൽ ജോലി', '4 ലക്ഷം രൂപ', 'live', 'APPROVED', 'Approved',
  'adminReview', 'Free', true, true, false, false, false, 0,
  'വയലിൽ', 'AB+', 176, 68, 'വടകര', 'പേരാമ്പ്ര', '673490', 'മാതാവും പിതാവും അടങ്ങുന്ന സന്തുഷ്ട കുടുംബം.', '["വായിക്കുക", "കൃഷി ചെയ്യുക", "യാത്ര ചെയ്യുക"]'
);
INSERT INTO public.kurichiyar_profiles (
  id, created_at, updated_at, phone, email, full_name, name, age, gender, dob, photo_url,
  father_tharavadu, mother_tharavadu, father_clan_id, mother_clan_id, district, state,
  about_me, education_level, occupation, income, registration_status, status, approval_status,
  account_status, subscription_tier, is_dummy, photo_approved, is_banned, is_agent, is_out_of_caste, report_count,
  house_name, blood_group, height_cm, weight_kg, taluk, post_office, pincode, family_details, hobbies
) VALUES (
  '7037d077-0069-48bc-a9e3-d2e428e71f39', now(), now(), '+919900010003', 'dummy_boy_4@auth.kurichiyar.com', 'വിജയൻ വയലിൽ', 'വിജയൻ വയലിൽ', 30, 'male', '1995-09-24', 'https://noidreeslytswkmsnmcn.supabase.co/storage/v1/object/public/user_documents/profile_photos/placeholder_male.png',
  'പുച്ചിയേരി (ചായിമ്മൽ)', 'കല്ലിയോടൻ (കല്ലിയോട്ട്)', 10, 9, 'കോഴിക്കോട്', 'Kerala',
  'വിദ്യാഭ്യാസമുള്ളതും ലളിതമായ സ്വഭാവമുള്ളതുമായ ഒരു ജീവിതപങ്കാളിയെ ആഗ്രഹിക്കുന്നു. പരസ്പരം മനസ്സിലാക്കി ജീവിക്കാൻ കഴിയണം.', 'എം.എസ്.സി. ബിരുദം', 'കൃഷി', '4 ലക്ഷം രൂപ', 'live', 'APPROVED', 'Approved',
  'adminReview', 'Free', true, true, false, false, false, 0,
  'വയലിൽ', 'B-', 181, 73, 'കൊയിലാണ്ടി', 'കോടുവള്ളി', '673488', 'മാതാവും പിതാവും അടങ്ങുന്ന സന്തുഷ്ട കുടുംബം.', '["വായിക്കുക", "കൃഷി ചെയ്യുക", "യാത്ര ചെയ്യുക"]'
);
INSERT INTO public.kurichiyar_profiles (
  id, created_at, updated_at, phone, email, full_name, name, age, gender, dob, photo_url,
  father_tharavadu, mother_tharavadu, father_clan_id, mother_clan_id, district, state,
  about_me, education_level, occupation, income, registration_status, status, approval_status,
  account_status, subscription_tier, is_dummy, photo_approved, is_banned, is_agent, is_out_of_caste, report_count,
  house_name, blood_group, height_cm, weight_kg, taluk, post_office, pincode, family_details, hobbies
) VALUES (
  'ffd7f932-f02c-4090-97da-fb20e608de1c', now(), now(), '+919900010004', 'dummy_boy_5@auth.kurichiyar.com', 'രാമൻ മണൽവയൽ', 'രാമൻ മണൽവയൽ', 32, 'male', '1994-01-12', 'https://noidreeslytswkmsnmcn.supabase.co/storage/v1/object/public/user_documents/profile_photos/placeholder_male.png',
  'എടപ്പിടി (എടപ്പിടി)', 'വെള്ളരി മിലിയാടി (വെള്ളരി)', 15, 36, 'കണ്ണൂർ', 'Kerala',
  'സ്വകാര്യ സ്ഥാപനത്തിൽ ജോലി ചെയ്യുന്നു. കുടുംബത്തിന് വലിയ പ്രാധാന്യം നൽകുന്നു. യോജിച്ച ഒരു പെൺകുട്ടിയെ തേടുന്നു.', 'എം.സി.എ', 'സ്വകാര്യ കമ്പനി ജോലി', '1 ലക്ഷം രൂപ', 'live', 'APPROVED', 'Approved',
  'adminReview', 'Free', true, true, false, false, false, 0,
  'മണൽവയൽ', 'A-', 163, 66, 'തലശ്ശേരി', 'പേരാവൂർ', '673899', 'മാതാവും പിതാവും അടങ്ങുന്ന സന്തുഷ്ട കുടുംബം.', '["വായിക്കുക", "കൃഷി ചെയ്യുക", "യാത്ര ചെയ്യുക"]'
);
INSERT INTO public.kurichiyar_profiles (
  id, created_at, updated_at, phone, email, full_name, name, age, gender, dob, photo_url,
  father_tharavadu, mother_tharavadu, father_clan_id, mother_clan_id, district, state,
  about_me, education_level, occupation, income, registration_status, status, approval_status,
  account_status, subscription_tier, is_dummy, photo_approved, is_banned, is_agent, is_out_of_caste, report_count,
  house_name, blood_group, height_cm, weight_kg, taluk, post_office, pincode, family_details, hobbies
) VALUES (
  '5ab8b66b-2600-4880-bc32-029e8da85b9d', now(), now(), '+919900010005', 'dummy_boy_6@auth.kurichiyar.com', 'കേളൻ എടത്തറ', 'കേളൻ എടത്തറ', 29, 'male', '1996-12-06', 'https://noidreeslytswkmsnmcn.supabase.co/storage/v1/object/public/user_documents/profile_photos/placeholder_male.png',
  'പൂരിഞ്ഞി മിലിയാടി (പൂരിഞ്ഞിൽ)', 'കുന്നംകൊലൻ (ചേരിമ്മൽ)', 34, 13, 'കണ്ണൂർ', 'Kerala',
  'സർക്കാർ ജോലി ചെയ്യുന്നു. മാതാപിതാക്കളോടൊപ്പം വയനാട്ടിലാണ് താമസം. കുടുംബസ്നേഹമുള്ള ഒരു പങ്കാളിയെ തേടുന്നു.', 'പ്ലസ് ടു', 'കൃഷി', '5 ലക്ഷം രൂപ', 'live', 'APPROVED', 'Approved',
  'adminReview', 'Free', true, true, false, false, false, 0,
  'എടത്തറ', 'A+', 170, 75, 'തളിപ്പറമ്പ്', 'മട്ടന്നൂർ', '673238', 'മാതാവും പിതാവും അടങ്ങുന്ന സന്തുഷ്ട കുടുംബം.', '["വായിക്കുക", "കൃഷി ചെയ്യുക", "യാത്ര ചെയ്യുക"]'
);
INSERT INTO public.kurichiyar_profiles (
  id, created_at, updated_at, phone, email, full_name, name, age, gender, dob, photo_url,
  father_tharavadu, mother_tharavadu, father_clan_id, mother_clan_id, district, state,
  about_me, education_level, occupation, income, registration_status, status, approval_status,
  account_status, subscription_tier, is_dummy, photo_approved, is_banned, is_agent, is_out_of_caste, report_count,
  house_name, blood_group, height_cm, weight_kg, taluk, post_office, pincode, family_details, hobbies
) VALUES (
  'e01b6bde-0da3-4fa4-b3d3-77197b82c742', now(), now(), '+919900010006', 'dummy_boy_7@auth.kurichiyar.com', 'കൃഷ്ണൻ കിഴക്കേവീട്', 'കൃഷ്ണൻ കിഴക്കേവീട്', 25, 'male', '2001-04-26', 'https://noidreeslytswkmsnmcn.supabase.co/storage/v1/object/public/user_documents/profile_photos/placeholder_male.png',
  'കുറ്റിയോട്ട് കുറ്റിയോടൻ (കുറ്റിയോട്ട്)', 'കോലിയൻ (നിറ്റാര)', 19, 20, 'വയനാട്', 'Kerala',
  'സർക്കാർ ജോലി ചെയ്യുന്നു. മാതാപിതാക്കളോടൊപ്പം വയനാട്ടിലാണ് താമസം. കുടുംബസ്നേഹമുള്ള ഒരു പങ്കാളിയെ തേടുന്നു.', 'ബി.എ. ബിരുദം', 'കൃഷി', '3 ലക്ഷം രൂപ', 'live', 'APPROVED', 'Approved',
  'adminReview', 'Free', true, true, false, false, false, 0,
  'കിഴക്കേവീട്', 'A+', 185, 58, 'വൈത്തിരി', 'മീനങ്ങാടി', '673466', 'മാതാവും പിതാവും അടങ്ങുന്ന സന്തുഷ്ട കുടുംബം.', '["വായിക്കുക", "കൃഷി ചെയ്യുക", "യാത്ര ചെയ്യുക"]'
);
INSERT INTO public.kurichiyar_profiles (
  id, created_at, updated_at, phone, email, full_name, name, age, gender, dob, photo_url,
  father_tharavadu, mother_tharavadu, father_clan_id, mother_clan_id, district, state,
  about_me, education_level, occupation, income, registration_status, status, approval_status,
  account_status, subscription_tier, is_dummy, photo_approved, is_banned, is_agent, is_out_of_caste, report_count,
  house_name, blood_group, height_cm, weight_kg, taluk, post_office, pincode, family_details, hobbies
) VALUES (
  'b5da801a-07bc-4f61-9dde-160d854a1303', now(), now(), '+919900010007', 'dummy_boy_8@auth.kurichiyar.com', 'ഷാജി വയലിൽ', 'ഷാജി വയലിൽ', 27, 'male', '1998-09-23', 'https://noidreeslytswkmsnmcn.supabase.co/storage/v1/object/public/user_documents/profile_photos/placeholder_male.png',
  'ചാൽപ്പ (പിൽപ്പിടി - പള്ളിയറ)', 'കുന്നംകൊലൻ (ചേരിമ്മൽ)', 52, 13, 'കോഴിക്കോട്', 'Kerala',
  'വിദ്യാഭ്യാസമുള്ളതും ലളിതമായ സ്വഭാവമുള്ളതുമായ ഒരു ജീവിതപങ്കാളിയെ ആഗ്രഹിക്കുന്നു. പരസ്പരം മനസ്സിലാക്കി ജീവിക്കാൻ കഴിയണം.', 'ബി.കോം ബിരുദം', 'സ്റ്റാഫ് നഴ്സ്', '1 ലക്ഷം രൂപ', 'live', 'APPROVED', 'Approved',
  'adminReview', 'Free', true, true, false, false, false, 0,
  'വയലിൽ', 'B+', 179, 59, 'താമരശ്ശേരി', 'ബാലുശ്ശേരി', '673492', 'മാതാവും പിതാവും അടങ്ങുന്ന സന്തുഷ്ട കുടുംബം.', '["വായിക്കുക", "കൃഷി ചെയ്യുക", "യാത്ര ചെയ്യുക"]'
);
INSERT INTO public.kurichiyar_profiles (
  id, created_at, updated_at, phone, email, full_name, name, age, gender, dob, photo_url,
  father_tharavadu, mother_tharavadu, father_clan_id, mother_clan_id, district, state,
  about_me, education_level, occupation, income, registration_status, status, approval_status,
  account_status, subscription_tier, is_dummy, photo_approved, is_banned, is_agent, is_out_of_caste, report_count,
  house_name, blood_group, height_cm, weight_kg, taluk, post_office, pincode, family_details, hobbies
) VALUES (
  '52d63c4d-3fa6-47af-aaa5-c8b609832a0a', now(), now(), '+919900010008', 'dummy_boy_9@auth.kurichiyar.com', 'ബാബു എടത്തറ', 'ബാബു എടത്തറ', 26, 'male', '2000-01-21', 'https://noidreeslytswkmsnmcn.supabase.co/storage/v1/object/public/user_documents/profile_photos/placeholder_male.png',
  'എടത്തണ (എടത്തണ)', 'കൊടിയേരി (പൂലായ്ക്കൽ)', 7, 26, 'കോഴിക്കോട്', 'Kerala',
  'ഞാൻ വയനാട്ടിൽ നിന്നുള്ള ഒരു ലളിതജീവിതം നയിക്കുന്ന ആളാണ്. കൃഷിയും ജോലിയിലുമാണ് താല്പര്യം. നല്ലൊരു കുടുംബജീവിതം ആഗ്രഹിക്കുന്നു.', 'എം.സി.എ', 'തയ്യൽ ജോലി', '4 ലക്ഷം രൂപ', 'live', 'APPROVED', 'Approved',
  'adminReview', 'Free', true, true, false, false, false, 0,
  'എടത്തറ', 'O+', 181, 61, 'താമരശ്ശേരി', 'പേരാമ്പ്ര', '673500', 'മാതാവും പിതാവും അടങ്ങുന്ന സന്തുഷ്ട കുടുംബം.', '["വായിക്കുക", "കൃഷി ചെയ്യുക", "യാത്ര ചെയ്യുക"]'
);
INSERT INTO public.kurichiyar_profiles (
  id, created_at, updated_at, phone, email, full_name, name, age, gender, dob, photo_url,
  father_tharavadu, mother_tharavadu, father_clan_id, mother_clan_id, district, state,
  about_me, education_level, occupation, income, registration_status, status, approval_status,
  account_status, subscription_tier, is_dummy, photo_approved, is_banned, is_agent, is_out_of_caste, report_count,
  house_name, blood_group, height_cm, weight_kg, taluk, post_office, pincode, family_details, hobbies
) VALUES (
  '337ec196-e69c-48d5-8cec-27d04668353e', now(), now(), '+919900010009', 'dummy_boy_10@auth.kurichiyar.com', 'മധു കുനിയിൽ', 'മധു കുനിയിൽ', 24, 'male', '2002-06-14', 'https://noidreeslytswkmsnmcn.supabase.co/storage/v1/object/public/user_documents/profile_photos/placeholder_male.png',
  'നെല്ലുകുടിയൻ (കാക്കോത്തറ)', 'പുത്തൂർ (കൊമ്മയാട്)', 4, 21, 'കോഴിക്കോട്', 'Kerala',
  'സ്വകാര്യ സ്ഥാപനത്തിൽ ജോലി ചെയ്യുന്നു. കുടുംബത്തിന് വലിയ പ്രാധാന്യം നൽകുന്നു. യോജിച്ച ഒരു പെൺകുട്ടിയെ തേടുന്നു.', 'എം.എ. ബിരുദം', 'അധ്യാപകൻ', '5 ലക്ഷം രൂപ', 'live', 'APPROVED', 'Approved',
  'adminReview', 'Free', true, true, false, false, false, 0,
  'കുനിയിൽ', 'B+', 169, 76, 'വടകര', 'പേരാമ്പ്ര', '673480', 'മാതാവും പിതാവും അടങ്ങുന്ന സന്തുഷ്ട കുടുംബം.', '["വായിക്കുക", "കൃഷി ചെയ്യുക", "യാത്ര ചെയ്യുക"]'
);
INSERT INTO public.kurichiyar_profiles (
  id, created_at, updated_at, phone, email, full_name, name, age, gender, dob, photo_url,
  father_tharavadu, mother_tharavadu, father_clan_id, mother_clan_id, district, state,
  about_me, education_level, occupation, income, registration_status, status, approval_status,
  account_status, subscription_tier, is_dummy, photo_approved, is_banned, is_agent, is_out_of_caste, report_count,
  house_name, blood_group, height_cm, weight_kg, taluk, post_office, pincode, family_details, hobbies
) VALUES (
  '17eec9df-5591-4ddc-8636-68b74b65d749', now(), now(), '+919900010010', 'dummy_boy_11@auth.kurichiyar.com', 'ഗിരീഷ് തറവാട്', 'ഗിരീഷ് തറവാട്', 31, 'male', '1994-09-01', 'https://noidreeslytswkmsnmcn.supabase.co/storage/v1/object/public/user_documents/profile_photos/placeholder_male.png',
  'വെള്ളരി മിലിയാടി (വെള്ളരി)', 'അയിനിയാടൻ (ചെന്നംപാടി)', 36, 51, 'കോഴിക്കോട്', 'Kerala',
  'ബിസിനസ്സ് ചെയ്യുന്നു. മാതാപിതാക്കളെ സ്നേഹത്തോടെ നോക്കുന്ന, നല്ലൊരു സ്വഭാവമുള്ള കുട്ടിയെ വിവാഹം കഴിക്കാൻ താല്പര്യമുണ്ട്.', 'ബി.ടെക് എഞ്ചിനീയറിംഗ്', 'സ്റ്റാഫ് നഴ്സ്', '5 ലക്ഷം രൂപ', 'live', 'APPROVED', 'Approved',
  'adminReview', 'Free', true, true, false, false, false, 0,
  'തറവാട്', 'B+', 172, 59, 'വടകര', 'ബാലുശ്ശേരി', '673823', 'മാതാവും പിതാവും അടങ്ങുന്ന സന്തുഷ്ട കുടുംബം.', '["വായിക്കുക", "കൃഷി ചെയ്യുക", "യാത്ര ചെയ്യുക"]'
);
INSERT INTO public.kurichiyar_profiles (
  id, created_at, updated_at, phone, email, full_name, name, age, gender, dob, photo_url,
  father_tharavadu, mother_tharavadu, father_clan_id, mother_clan_id, district, state,
  about_me, education_level, occupation, income, registration_status, status, approval_status,
  account_status, subscription_tier, is_dummy, photo_approved, is_banned, is_agent, is_out_of_caste, report_count,
  house_name, blood_group, height_cm, weight_kg, taluk, post_office, pincode, family_details, hobbies
) VALUES (
  '7a1f0b2b-ee0c-43c3-9297-0484016530fe', now(), now(), '+919900010011', 'dummy_boy_12@auth.kurichiyar.com', 'രാജേഷ് കുന്നിൻമേൽ', 'രാജേഷ് കുന്നിൻമേൽ', 27, 'male', '1999-02-21', 'https://noidreeslytswkmsnmcn.supabase.co/storage/v1/object/public/user_documents/profile_photos/placeholder_male.png',
  'ചമ്മിയേരി (താഴെ തലപ്പുഴ)', 'പെരിഞ്ചോല (പെരിഞ്ചേ)', 45, 56, 'കോഴിക്കോട്', 'Kerala',
  'സർക്കാർ ജോലി ചെയ്യുന്നു. മാതാപിതാക്കളോടൊപ്പം വയനാട്ടിലാണ് താമസം. കുടുംബസ്നേഹമുള്ള ഒരു പങ്കാളിയെ തേടുന്നു.', 'ബി.എ. ബിരുദം', 'അധ്യാപകൻ', '5 ലക്ഷം രൂപ', 'live', 'APPROVED', 'Approved',
  'adminReview', 'Free', true, true, false, false, false, 0,
  'കുന്നിൻമേൽ', 'AB+', 167, 62, 'വടകര', 'കോടുവള്ളി', '673727', 'മാതാവും പിതാവും അടങ്ങുന്ന സന്തുഷ്ട കുടുംബം.', '["വായിക്കുക", "കൃഷി ചെയ്യുക", "യാത്ര ചെയ്യുക"]'
);
INSERT INTO public.kurichiyar_profiles (
  id, created_at, updated_at, phone, email, full_name, name, age, gender, dob, photo_url,
  father_tharavadu, mother_tharavadu, father_clan_id, mother_clan_id, district, state,
  about_me, education_level, occupation, income, registration_status, status, approval_status,
  account_status, subscription_tier, is_dummy, photo_approved, is_banned, is_agent, is_out_of_caste, report_count,
  house_name, blood_group, height_cm, weight_kg, taluk, post_office, pincode, family_details, hobbies
) VALUES (
  '88d65b16-9265-42fb-9948-e1485c2e3a07', now(), now(), '+919900010012', 'dummy_boy_13@auth.kurichiyar.com', 'സുരേഷ് കുനിയിൽ', 'സുരേഷ് കുനിയിൽ', 31, 'male', '1995-02-05', 'https://noidreeslytswkmsnmcn.supabase.co/storage/v1/object/public/user_documents/profile_photos/placeholder_male.png',
  'തോട്ടായി (എടലകുനി)', 'കൊന്നിയോടൻ (കൊന്നിയോട്ട്)', 38, 39, 'കണ്ണൂർ', 'Kerala',
  'സർക്കാർ ജോലി ചെയ്യുന്നു. മാതാപിതാക്കളോടൊപ്പം വയനാട്ടിലാണ് താമസം. കുടുംബസ്നേഹമുള്ള ഒരു പങ്കാളിയെ തേടുന്നു.', 'എം.സി.എ', 'തയ്യൽ ജോലി', '2 ലക്ഷം രൂപ', 'live', 'APPROVED', 'Approved',
  'adminReview', 'Free', true, true, false, false, false, 0,
  'കുനിയിൽ', 'A+', 170, 55, 'തലശ്ശേരി', 'കേളകം', '673939', 'മാതാവും പിതാവും അടങ്ങുന്ന സന്തുഷ്ട കുടുംബം.', '["വായിക്കുക", "കൃഷി ചെയ്യുക", "യാത്ര ചെയ്യുക"]'
);
INSERT INTO public.kurichiyar_profiles (
  id, created_at, updated_at, phone, email, full_name, name, age, gender, dob, photo_url,
  father_tharavadu, mother_tharavadu, father_clan_id, mother_clan_id, district, state,
  about_me, education_level, occupation, income, registration_status, status, approval_status,
  account_status, subscription_tier, is_dummy, photo_approved, is_banned, is_agent, is_out_of_caste, report_count,
  house_name, blood_group, height_cm, weight_kg, taluk, post_office, pincode, family_details, hobbies
) VALUES (
  '34dd5e74-aa9d-4da9-82d5-ac3bd243e74d', now(), now(), '+919900010013', 'dummy_boy_14@auth.kurichiyar.com', 'അനീഷ് കുന്നിൻമേൽ', 'അനീഷ് കുന്നിൻമേൽ', 24, 'male', '2001-12-16', 'https://noidreeslytswkmsnmcn.supabase.co/storage/v1/object/public/user_documents/profile_photos/placeholder_male.png',
  'അയിനിയാടൻ (ചെന്നംപാടി)', 'എരിശേരി (ചേരള)', 51, 50, 'കോഴിക്കോട്', 'Kerala',
  'ഞാൻ വയനാട്ടിൽ നിന്നുള്ള ഒരു ലളിതജീവിതം നയിക്കുന്ന ആളാണ്. കൃഷിയും ജോലിയിലുമാണ് താല്പര്യം. നല്ലൊരു കുടുംബജീവിതം ആഗ്രഹിക്കുന്നു.', 'ബി.എസ്.സി. ബിരുദം', 'വ്യാപാരി', '5 ലക്ഷം രൂപ', 'live', 'APPROVED', 'Approved',
  'adminReview', 'Free', true, true, false, false, false, 0,
  'കുന്നിൻമേൽ', 'A+', 179, 66, 'വടകര', 'പേരാമ്പ്ര', '673398', 'മാതാവും പിതാവും അടങ്ങുന്ന സന്തുഷ്ട കുടുംബം.', '["വായിക്കുക", "കൃഷി ചെയ്യുക", "യാത്ര ചെയ്യുക"]'
);
INSERT INTO public.kurichiyar_profiles (
  id, created_at, updated_at, phone, email, full_name, name, age, gender, dob, photo_url,
  father_tharavadu, mother_tharavadu, father_clan_id, mother_clan_id, district, state,
  about_me, education_level, occupation, income, registration_status, status, approval_status,
  account_status, subscription_tier, is_dummy, photo_approved, is_banned, is_agent, is_out_of_caste, report_count,
  house_name, blood_group, height_cm, weight_kg, taluk, post_office, pincode, family_details, hobbies
) VALUES (
  'e55277b9-488c-4d61-84c3-c5f66d1a3bf8', now(), now(), '+919900010014', 'dummy_boy_15@auth.kurichiyar.com', 'വിനീത് എടത്തറ', 'വിനീത് എടത്തറ', 29, 'male', '1996-09-06', 'https://noidreeslytswkmsnmcn.supabase.co/storage/v1/object/public/user_documents/profile_photos/placeholder_male.png',
  'തെറ്റ (വേങ്ങലോട്ട്)', 'ആനി തലക്കര (ആന്നി)', 40, 31, 'വയനാട്', 'Kerala',
  'സർക്കാർ ജോലി ചെയ്യുന്നു. മാതാപിതാക്കളോടൊപ്പം വയനാട്ടിലാണ് താമസം. കുടുംബസ്നേഹമുള്ള ഒരു പങ്കാളിയെ തേടുന്നു.', 'ബി.എ. ബിരുദം', 'കൃഷി', '2 ലക്ഷം രൂപ', 'live', 'APPROVED', 'Approved',
  'adminReview', 'Free', true, true, false, false, false, 0,
  'എടത്തറ', 'A-', 170, 73, 'മാനന്തവാടി', 'മീനങ്ങാടി', '673518', 'മാതാവും പിതാവും അടങ്ങുന്ന സന്തുഷ്ട കുടുംബം.', '["വായിക്കുക", "കൃഷി ചെയ്യുക", "യാത്ര ചെയ്യുക"]'
);
INSERT INTO public.kurichiyar_profiles (
  id, created_at, updated_at, phone, email, full_name, name, age, gender, dob, photo_url,
  father_tharavadu, mother_tharavadu, father_clan_id, mother_clan_id, district, state,
  about_me, education_level, occupation, income, registration_status, status, approval_status,
  account_status, subscription_tier, is_dummy, photo_approved, is_banned, is_agent, is_out_of_caste, report_count,
  house_name, blood_group, height_cm, weight_kg, taluk, post_office, pincode, family_details, hobbies
) VALUES (
  '5e1c0f1c-51df-47ea-ba7f-5abc5a25316b', now(), now(), '+919900010015', 'dummy_boy_16@auth.kurichiyar.com', 'സജീവ് മീത്തൽ', 'സജീവ് മീത്തൽ', 32, 'male', '1993-09-10', 'https://noidreeslytswkmsnmcn.supabase.co/storage/v1/object/public/user_documents/profile_photos/placeholder_male.png',
  'വളാടൻ (ഇല്ലത്തുമൂല)', 'വെണ്ണിയോറ (വെണ്ണിയോറ)', 5, 23, 'കണ്ണൂർ', 'Kerala',
  'വിദ്യാഭ്യാസമുള്ളതും ലളിതമായ സ്വഭാവമുള്ളതുമായ ഒരു ജീവിതപങ്കാളിയെ ആഗ്രഹിക്കുന്നു. പരസ്പരം മനസ്സിലാക്കി ജീവിക്കാൻ കഴിയണം.', 'ബി.ടെക് എഞ്ചിനീയറിംഗ്', 'വ്യാപാരി', '5 ലക്ഷം രൂപ', 'live', 'APPROVED', 'Approved',
  'adminReview', 'Free', true, true, false, false, false, 0,
  'മീത്തൽ', 'B-', 176, 66, 'തലശ്ശേരി', 'കേളകം', '673144', 'മാതാവും പിതാവും അടങ്ങുന്ന സന്തുഷ്ട കുടുംബം.', '["വായിക്കുക", "കൃഷി ചെയ്യുക", "യാത്ര ചെയ്യുക"]'
);
INSERT INTO public.kurichiyar_profiles (
  id, created_at, updated_at, phone, email, full_name, name, age, gender, dob, photo_url,
  father_tharavadu, mother_tharavadu, father_clan_id, mother_clan_id, district, state,
  about_me, education_level, occupation, income, registration_status, status, approval_status,
  account_status, subscription_tier, is_dummy, photo_approved, is_banned, is_agent, is_out_of_caste, report_count,
  house_name, blood_group, height_cm, weight_kg, taluk, post_office, pincode, family_details, hobbies
) VALUES (
  '2ae5a186-74b5-4596-9c1d-b62b0391f858', now(), now(), '+919900010016', 'dummy_boy_17@auth.kurichiyar.com', 'മനു ചാലിൽ', 'മനു ചാലിൽ', 27, 'male', '1999-07-21', 'https://noidreeslytswkmsnmcn.supabase.co/storage/v1/object/public/user_documents/profile_photos/placeholder_male.png',
  'തോട്ടായി (എടലകുനി)', 'വെണ്ണിയോറ (വെണ്ണിയോറ)', 38, 23, 'കോഴിക്കോട്', 'Kerala',
  'ഞാൻ വയനാട്ടിൽ നിന്നുള്ള ഒരു ലളിതജീവിതം നയിക്കുന്ന ആളാണ്. കൃഷിയും ജോലിയിലുമാണ് താല്പര്യം. നല്ലൊരു കുടുംബജീവിതം ആഗ്രഹിക്കുന്നു.', 'ബി.ടെക് എഞ്ചിനീയറിംഗ്', 'софтവെയർ എഞ്ചിനീയർ', '4 ലക്ഷം രൂപ', 'live', 'APPROVED', 'Approved',
  'adminReview', 'Free', true, true, false, false, false, 0,
  'ചാലിൽ', 'AB+', 171, 80, 'താമരശ്ശേരി', 'പേരാമ്പ്ര', '673560', 'മാതാവും പിതാവും അടങ്ങുന്ന സന്തുഷ്ട കുടുംബം.', '["വായിക്കുക", "കൃഷി ചെയ്യുക", "യാത്ര ചെയ്യുക"]'
);
INSERT INTO public.kurichiyar_profiles (
  id, created_at, updated_at, phone, email, full_name, name, age, gender, dob, photo_url,
  father_tharavadu, mother_tharavadu, father_clan_id, mother_clan_id, district, state,
  about_me, education_level, occupation, income, registration_status, status, approval_status,
  account_status, subscription_tier, is_dummy, photo_approved, is_banned, is_agent, is_out_of_caste, report_count,
  house_name, blood_group, height_cm, weight_kg, taluk, post_office, pincode, family_details, hobbies
) VALUES (
  '0366736d-2b92-49b4-8458-69e9760bdd4a', now(), now(), '+919900010017', 'dummy_boy_18@auth.kurichiyar.com', 'വിപിൻ തറവാട്', 'വിപിൻ തറവാട്', 25, 'male', '2001-04-28', 'https://noidreeslytswkmsnmcn.supabase.co/storage/v1/object/public/user_documents/profile_photos/placeholder_male.png',
  'കല്ലിയോടൻ (കല്ലിയോട്ട്)', 'പുതിയിടം ചമ്മിയേരി (പുതിയിടം)', 9, 46, 'കോഴിക്കോട്', 'Kerala',
  'ഞാൻ വയനാട്ടിൽ നിന്നുള്ള ഒരു ലളിതജീവിതം നയിക്കുന്ന ആളാണ്. കൃഷിയും ജോലിയിലുമാണ് താല്പര്യം. നല്ലൊരു കുടുംബജീവിതം ആഗ്രഹിക്കുന്നു.', 'ബി.കോം ബിരുദം', 'കൃഷി', '5 ലക്ഷം രൂപ', 'live', 'APPROVED', 'Approved',
  'adminReview', 'Free', true, true, false, false, false, 0,
  'തറവാട്', 'B-', 180, 78, 'വടകര', 'ബാലുശ്ശേരി', '673230', 'മാതാവും പിതാവും അടങ്ങുന്ന സന്തുഷ്ട കുടുംബം.', '["വായിക്കുക", "കൃഷി ചെയ്യുക", "യാത്ര ചെയ്യുക"]'
);
INSERT INTO public.kurichiyar_profiles (
  id, created_at, updated_at, phone, email, full_name, name, age, gender, dob, photo_url,
  father_tharavadu, mother_tharavadu, father_clan_id, mother_clan_id, district, state,
  about_me, education_level, occupation, income, registration_status, status, approval_status,
  account_status, subscription_tier, is_dummy, photo_approved, is_banned, is_agent, is_out_of_caste, report_count,
  house_name, blood_group, height_cm, weight_kg, taluk, post_office, pincode, family_details, hobbies
) VALUES (
  '7c55fee9-f518-4d56-b5ab-329ddcbebc88', now(), now(), '+919900010018', 'dummy_boy_19@auth.kurichiyar.com', 'ജിതിൻ പടിഞ്ഞാറേവീട്', 'ജിതിൻ പടിഞ്ഞാറേവീട്', 32, 'male', '1994-07-09', 'https://noidreeslytswkmsnmcn.supabase.co/storage/v1/object/public/user_documents/profile_photos/placeholder_male.png',
  'പാടിയേരി (ഞാരലോട്ട്)', 'പുച്ചിയേരി (ചായിമ്മൽ)', 41, 10, 'വയനാട്', 'Kerala',
  'ഞാൻ വയനാട്ടിൽ നിന്നുള്ള ഒരു ലളിതജീവിതം നയിക്കുന്ന ആളാണ്. കൃഷിയും ജോലിയിലുമാണ് താല്പര്യം. നല്ലൊരു കുടുംബജീവിതം ആഗ്രഹിക്കുന്നു.', 'ജനറൽ നഴ്സിംഗ്', 'വ്യാപാരി', '3 ലക്ഷം രൂപ', 'live', 'APPROVED', 'Approved',
  'adminReview', 'Free', true, true, false, false, false, 0,
  'പടിഞ്ഞാറേവീട്', 'A+', 181, 73, 'വൈത്തിരി', 'കല്പറ്റ', '673454', 'മാതാവും പിതാവും അടങ്ങുന്ന സന്തുഷ്ട കുടുംബം.', '["വായിക്കുക", "കൃഷി ചെയ്യുക", "യാത്ര ചെയ്യുക"]'
);
INSERT INTO public.kurichiyar_profiles (
  id, created_at, updated_at, phone, email, full_name, name, age, gender, dob, photo_url,
  father_tharavadu, mother_tharavadu, father_clan_id, mother_clan_id, district, state,
  about_me, education_level, occupation, income, registration_status, status, approval_status,
  account_status, subscription_tier, is_dummy, photo_approved, is_banned, is_agent, is_out_of_caste, report_count,
  house_name, blood_group, height_cm, weight_kg, taluk, post_office, pincode, family_details, hobbies
) VALUES (
  'c054482d-127b-4faf-ad9d-33fccc19386f', now(), now(), '+919900010019', 'dummy_boy_20@auth.kurichiyar.com', 'മിഥുൻ തറവാട്', 'മിഥുൻ തറവാട്', 28, 'male', '1998-01-25', 'https://noidreeslytswkmsnmcn.supabase.co/storage/v1/object/public/user_documents/profile_photos/placeholder_male.png',
  'കരിമ്പിച്ചി (കോടങ്ങേല)', 'കോലിയൻ (നിറ്റാര)', 28, 20, 'കോഴിക്കോട്', 'Kerala',
  'ഞാൻ വയനാട്ടിൽ നിന്നുള്ള ഒരു ലളിതജീവിതം നയിക്കുന്ന ആളാണ്. കൃഷിയും ജോലിയിലുമാണ് താല്പര്യം. നല്ലൊരു കുടുംബജീവിതം ആഗ്രഹിക്കുന്നു.', 'ബി.എസ്.സി. ബിരുദം', 'അധ്യാപകൻ', '2 ലക്ഷം രൂപ', 'live', 'APPROVED', 'Approved',
  'adminReview', 'Free', true, true, false, false, false, 0,
  'തറവാട്', 'AB+', 182, 71, 'കൊയിലാണ്ടി', 'പേരാമ്പ്ര', '673207', 'മാതാവും പിതാവും അടങ്ങുന്ന സന്തുഷ്ട കുടുംബം.', '["വായിക്കുക", "കൃഷി ചെയ്യുക", "യാത്ര ചെയ്യുക"]'
);
INSERT INTO public.kurichiyar_profiles (
  id, created_at, updated_at, phone, email, full_name, name, age, gender, dob, photo_url,
  father_tharavadu, mother_tharavadu, father_clan_id, mother_clan_id, district, state,
  about_me, education_level, occupation, income, registration_status, status, approval_status,
  account_status, subscription_tier, is_dummy, photo_approved, is_banned, is_agent, is_out_of_caste, report_count,
  house_name, blood_group, height_cm, weight_kg, taluk, post_office, pincode, family_details, hobbies
) VALUES (
  '26087f2d-11a6-4ebe-acd0-0227417a6d93', now(), now(), '+919900010020', 'dummy_boy_21@auth.kurichiyar.com', 'അഖിൽ പുത്തൻവീട്', 'അഖിൽ പുത്തൻവീട്', 28, 'male', '1998-05-12', 'https://noidreeslytswkmsnmcn.supabase.co/storage/v1/object/public/user_documents/profile_photos/placeholder_male.png',
  'ചെരൂല് (മേനരത്ത്)', 'കൊടിയേരി (പൂലായ്ക്കൽ)', 49, 26, 'കോഴിക്കോട്', 'Kerala',
  'വിദ്യാഭ്യാസമുള്ളതും ലളിതമായ സ്വഭാവമുള്ളതുമായ ഒരു ജീവിതപങ്കാളിയെ ആഗ്രഹിക്കുന്നു. പരസ്പരം മനസ്സിലാക്കി ജീവിക്കാൻ കഴിയണം.', 'ബി.ടെക് എഞ്ചിനീയറിംഗ്', 'അധ്യാപകൻ', '3 ലക്ഷം രൂപ', 'live', 'APPROVED', 'Approved',
  'adminReview', 'Free', true, true, false, false, false, 0,
  'പുത്തൻവീട്', 'A+', 169, 74, 'കൊയിലാണ്ടി', 'ബാലുശ്ശേരി', '673452', 'മാതാവും പിതാവും അടങ്ങുന്ന സന്തുഷ്ട കുടുംബം.', '["വായിക്കുക", "കൃഷി ചെയ്യുക", "യാത്ര ചെയ്യുക"]'
);
INSERT INTO public.kurichiyar_profiles (
  id, created_at, updated_at, phone, email, full_name, name, age, gender, dob, photo_url,
  father_tharavadu, mother_tharavadu, father_clan_id, mother_clan_id, district, state,
  about_me, education_level, occupation, income, registration_status, status, approval_status,
  account_status, subscription_tier, is_dummy, photo_approved, is_banned, is_agent, is_out_of_caste, report_count,
  house_name, blood_group, height_cm, weight_kg, taluk, post_office, pincode, family_details, hobbies
) VALUES (
  '0e81fb12-e35e-4823-a69d-70002b76c62e', now(), now(), '+919900010021', 'dummy_boy_22@auth.kurichiyar.com', 'രാഹുൽ എടക്കുടി', 'രാഹുൽ എടക്കുടി', 30, 'male', '1995-12-29', 'https://noidreeslytswkmsnmcn.supabase.co/storage/v1/object/public/user_documents/profile_photos/placeholder_male.png',
  'തെറ്റ (വേങ്ങലോട്ട്)', 'കരിമ്പിലിച്ചി (നെടുമ്പിലാശ്ശേരി)', 40, 3, 'കോഴിക്കോട്', 'Kerala',
  'സർക്കാർ ജോലി ചെയ്യുന്നു. മാതാപിതാക്കളോടൊപ്പം വയനാട്ടിലാണ് താമസം. കുടുംബസ്നേഹമുള്ള ഒരു പങ്കാളിയെ തേടുന്നു.', 'എസ്.എസ്.എൽ.സി', 'സ്വകാര്യ കമ്പനി ജോലി', '1 ലക്ഷം രൂപ', 'live', 'APPROVED', 'Approved',
  'adminReview', 'Free', true, true, false, false, false, 0,
  'എടക്കുടി', 'A-', 167, 61, 'കൊയിലാണ്ടി', 'കോടുവള്ളി', '673792', 'മാതാവും പിതാവും അടങ്ങുന്ന സന്തുഷ്ട കുടുംബം.', '["വായിക്കുക", "കൃഷി ചെയ്യുക", "യാത്ര ചെയ്യുക"]'
);
INSERT INTO public.kurichiyar_profiles (
  id, created_at, updated_at, phone, email, full_name, name, age, gender, dob, photo_url,
  father_tharavadu, mother_tharavadu, father_clan_id, mother_clan_id, district, state,
  about_me, education_level, occupation, income, registration_status, status, approval_status,
  account_status, subscription_tier, is_dummy, photo_approved, is_banned, is_agent, is_out_of_caste, report_count,
  house_name, blood_group, height_cm, weight_kg, taluk, post_office, pincode, family_details, hobbies
) VALUES (
  '886f35ab-739c-4af5-b609-78d9c1981e1e', now(), now(), '+919900010022', 'dummy_boy_23@auth.kurichiyar.com', 'ഗോകുൽ തെക്കേവീട്', 'ഗോകുൽ തെക്കേവീട്', 26, 'male', '1999-12-04', 'https://noidreeslytswkmsnmcn.supabase.co/storage/v1/object/public/user_documents/profile_photos/placeholder_male.png',
  'നെല്ലുകുടിയൻ (കാക്കോത്തറ)', 'മത്തളം കരിമ്പിച്ചി (മട്ടിലിയം)', 4, 29, 'കണ്ണൂർ', 'Kerala',
  'സർക്കാർ ജോലി ചെയ്യുന്നു. മാതാപിതാക്കളോടൊപ്പം വയനാട്ടിലാണ് താമസം. കുടുംബസ്നേഹമുള്ള ഒരു പങ്കാളിയെ തേടുന്നു.', 'എസ്.എസ്.എൽ.സി', 'വ്യാപാരി', '3 ലക്ഷം രൂപ', 'live', 'APPROVED', 'Approved',
  'adminReview', 'Free', true, true, false, false, false, 0,
  'തെക്കേവീട്', 'A+', 167, 77, 'തളിപ്പറമ്പ്', 'പേരാവൂർ', '673975', 'മാതാവും പിതാവും അടങ്ങുന്ന സന്തുഷ്ട കുടുംബം.', '["വായിക്കുക", "കൃഷി ചെയ്യുക", "യാത്ര ചെയ്യുക"]'
);
INSERT INTO public.kurichiyar_profiles (
  id, created_at, updated_at, phone, email, full_name, name, age, gender, dob, photo_url,
  father_tharavadu, mother_tharavadu, father_clan_id, mother_clan_id, district, state,
  about_me, education_level, occupation, income, registration_status, status, approval_status,
  account_status, subscription_tier, is_dummy, photo_approved, is_banned, is_agent, is_out_of_caste, report_count,
  house_name, blood_group, height_cm, weight_kg, taluk, post_office, pincode, family_details, hobbies
) VALUES (
  '75f19889-7109-4923-a229-1a07f568923e', now(), now(), '+919900010023', 'dummy_boy_24@auth.kurichiyar.com', 'ഹരീഷ് വയലിൽ', 'ഹരീഷ് വയലിൽ', 33, 'male', '1993-01-09', 'https://noidreeslytswkmsnmcn.supabase.co/storage/v1/object/public/user_documents/profile_photos/placeholder_male.png',
  'ഒതയോം കൊലൻ (ഒതയോത്ത്)', 'തോട്ടായി (എടലകുനി)', 14, 38, 'കോഴിക്കോട്', 'Kerala',
  'വിദ്യാഭ്യാസമുള്ളതും ലളിതമായ സ്വഭാവമുള്ളതുമായ ഒരു ജീവിതപങ്കാളിയെ ആഗ്രഹിക്കുന്നു. പരസ്പരം മനസ്സിലാക്കി ജീവിക്കാൻ കഴിയണം.', 'എം.എ. ബിരുദം', 'തയ്യൽ ജോലി', '4 ലക്ഷം രൂപ', 'live', 'APPROVED', 'Approved',
  'adminReview', 'Free', true, true, false, false, false, 0,
  'വയലിൽ', 'B+', 178, 72, 'കൊയിലാണ്ടി', 'ബാലുശ്ശേരി', '673760', 'മാതാവും പിതാവും അടങ്ങുന്ന സന്തുഷ്ട കുടുംബം.', '["വായിക്കുക", "കൃഷി ചെയ്യുക", "യാത്ര ചെയ്യുക"]'
);
INSERT INTO public.kurichiyar_profiles (
  id, created_at, updated_at, phone, email, full_name, name, age, gender, dob, photo_url,
  father_tharavadu, mother_tharavadu, father_clan_id, mother_clan_id, district, state,
  about_me, education_level, occupation, income, registration_status, status, approval_status,
  account_status, subscription_tier, is_dummy, photo_approved, is_banned, is_agent, is_out_of_caste, report_count,
  house_name, blood_group, height_cm, weight_kg, taluk, post_office, pincode, family_details, hobbies
) VALUES (
  '09bd04bc-783b-47bf-878b-3bdceaeb0ffb', now(), now(), '+919900010024', 'dummy_boy_25@auth.kurichiyar.com', 'ശ്രീജിത്ത് എടത്തറ', 'ശ്രീജിത്ത് എടത്തറ', 28, 'male', '1997-09-05', 'https://noidreeslytswkmsnmcn.supabase.co/storage/v1/object/public/user_documents/profile_photos/placeholder_male.png',
  'ആനി തലക്കര (ആന്നി)', 'പാടിയേരി (ഞാരലോട്ട്)', 31, 41, 'വയനാട്', 'Kerala',
  'ബിസിനസ്സ് ചെയ്യുന്നു. മാതാപിതാക്കളെ സ്നേഹത്തോടെ നോക്കുന്ന, നല്ലൊരു സ്വഭാവമുള്ള കുട്ടിയെ വിവാഹം കഴിക്കാൻ താല്പര്യമുണ്ട്.', 'ബി.എ. ബിരുദം', 'തയ്യൽ ജോലി', '5 ലക്ഷം രൂപ', 'live', 'APPROVED', 'Approved',
  'adminReview', 'Free', true, true, false, false, false, 0,
  'എടത്തറ', 'A-', 164, 69, 'മാനന്തവാടി', 'മീനങ്ങാടി', '673530', 'മാതാവും പിതാവും അടങ്ങുന്ന സന്തുഷ്ട കുടുംബം.', '["വായിക്കുക", "കൃഷി ചെയ്യുക", "യാത്ര ചെയ്യുക"]'
);
INSERT INTO public.kurichiyar_profiles (
  id, created_at, updated_at, phone, email, full_name, name, age, gender, dob, photo_url,
  father_tharavadu, mother_tharavadu, father_clan_id, mother_clan_id, district, state,
  about_me, education_level, occupation, income, registration_status, status, approval_status,
  account_status, subscription_tier, is_dummy, photo_approved, is_banned, is_agent, is_out_of_caste, report_count,
  house_name, blood_group, height_cm, weight_kg, taluk, post_office, pincode, family_details, hobbies
) VALUES (
  '64b51a70-1a48-4b5c-afea-20618bc456e5', now(), now(), '+919900010025', 'dummy_boy_26@auth.kurichiyar.com', 'ഉണ്ണികൃഷ്ണൻ പടിഞ്ഞാറേവീട്', 'ഉണ്ണികൃഷ്ണൻ പടിഞ്ഞാറേവീട്', 32, 'male', '1993-12-05', 'https://noidreeslytswkmsnmcn.supabase.co/storage/v1/object/public/user_documents/profile_photos/placeholder_male.png',
  'പുച്ചിയേരി (ചായിമ്മൽ)', 'പരക്കടൻ (വെള്ളോട്ട്)', 10, 48, 'കണ്ണൂർ', 'Kerala',
  'സ്വകാര്യ സ്ഥാപനത്തിൽ ജോലി ചെയ്യുന്നു. കുടുംബത്തിന് വലിയ പ്രാധാന്യം നൽകുന്നു. യോജിച്ച ഒരു പെൺകുട്ടിയെ തേടുന്നു.', 'ബി.എ. ബിരുദം', 'സർക്കാർ ജീവനക്കാരൻ', '3 ലക്ഷം രൂപ', 'live', 'APPROVED', 'Approved',
  'adminReview', 'Free', true, true, false, false, false, 0,
  'പടിഞ്ഞാറേവീട്', 'B+', 171, 80, 'തലശ്ശേരി', 'മട്ടന്നൂർ', '673610', 'മാതാവും പിതാവും അടങ്ങുന്ന സന്തുഷ്ട കുടുംബം.', '["വായിക്കുക", "കൃഷി ചെയ്യുക", "യാത്ര ചെയ്യുക"]'
);
INSERT INTO public.kurichiyar_profiles (
  id, created_at, updated_at, phone, email, full_name, name, age, gender, dob, photo_url,
  father_tharavadu, mother_tharavadu, father_clan_id, mother_clan_id, district, state,
  about_me, education_level, occupation, income, registration_status, status, approval_status,
  account_status, subscription_tier, is_dummy, photo_approved, is_banned, is_agent, is_out_of_caste, report_count,
  house_name, blood_group, height_cm, weight_kg, taluk, post_office, pincode, family_details, hobbies
) VALUES (
  'cdd0b5f8-2dc3-4238-943c-67c82352f7b1', now(), now(), '+919900010026', 'dummy_boy_27@auth.kurichiyar.com', 'മണികണ്ഠൻ വലിപ്പവീട്', 'മണികണ്ഠൻ വലിപ്പവീട്', 23, 'male', '2003-04-06', 'https://noidreeslytswkmsnmcn.supabase.co/storage/v1/object/public/user_documents/profile_photos/placeholder_male.png',
  'എടത്തണ (എടത്തണ)', 'ചെറുമ്പാലൻ (കാക്കൻ ചിറ)', 7, 24, 'കണ്ണൂർ', 'Kerala',
  'ഞാൻ വയനാട്ടിൽ നിന്നുള്ള ഒരു ലളിതജീവിതം നയിക്കുന്ന ആളാണ്. കൃഷിയും ജോലിയിലുമാണ് താല്പര്യം. നല്ലൊരു കുടുംബജീവിതം ആഗ്രഹിക്കുന്നു.', 'എം.എസ്.സി. ബിരുദം', 'ഡ്രൈവർ', '2 ലക്ഷം രൂപ', 'live', 'APPROVED', 'Approved',
  'adminReview', 'Free', true, true, false, false, false, 0,
  'വലിപ്പവീട്', 'B-', 181, 63, 'തളിപ്പറമ്പ്', 'കേളകം', '673598', 'മാതാവും പിതാവും അടങ്ങുന്ന സന്തുഷ്ട കുടുംബം.', '["വായിക്കുക", "കൃഷി ചെയ്യുക", "യാത്ര ചെയ്യുക"]'
);
INSERT INTO public.kurichiyar_profiles (
  id, created_at, updated_at, phone, email, full_name, name, age, gender, dob, photo_url,
  father_tharavadu, mother_tharavadu, father_clan_id, mother_clan_id, district, state,
  about_me, education_level, occupation, income, registration_status, status, approval_status,
  account_status, subscription_tier, is_dummy, photo_approved, is_banned, is_agent, is_out_of_caste, report_count,
  house_name, blood_group, height_cm, weight_kg, taluk, post_office, pincode, family_details, hobbies
) VALUES (
  'b31390c7-0647-42af-8daf-6e6ba9619ac4', now(), now(), '+919900010027', 'dummy_boy_28@auth.kurichiyar.com', 'പ്രദീപ് പടിഞ്ഞാറേവീട്', 'പ്രദീപ് പടിഞ്ഞാറേവീട്', 33, 'male', '1992-09-27', 'https://noidreeslytswkmsnmcn.supabase.co/storage/v1/object/public/user_documents/profile_photos/placeholder_male.png',
  'വളാടൻ (ഇല്ലത്തുമൂല)', 'നെല്ലുകുടിയൻ (കാക്കോത്തറ)', 5, 4, 'വയനാട്', 'Kerala',
  'ബിസിനസ്സ് ചെയ്യുന്നു. മാതാപിതാക്കളെ സ്നേഹത്തോടെ നോക്കുന്ന, നല്ലൊരു സ്വഭാവമുള്ള കുട്ടിയെ വിവാഹം കഴിക്കാൻ താല്പര്യമുണ്ട്.', 'എം.എ. ബിരുദം', 'സർക്കാർ ജീവനക്കാരൻ', '4 ലക്ഷം രൂപ', 'live', 'APPROVED', 'Approved',
  'adminReview', 'Free', true, true, false, false, false, 0,
  'പടിഞ്ഞാറേവീട്', 'A-', 185, 77, 'സുൽത്താൻ ബത്തേരി', 'കല്പറ്റ', '673706', 'മാതാവും പിതാവും അടങ്ങുന്ന സന്തുഷ്ട കുടുംബം.', '["വായിക്കുക", "കൃഷി ചെയ്യുക", "യാത്ര ചെയ്യുക"]'
);
INSERT INTO public.kurichiyar_profiles (
  id, created_at, updated_at, phone, email, full_name, name, age, gender, dob, photo_url,
  father_tharavadu, mother_tharavadu, father_clan_id, mother_clan_id, district, state,
  about_me, education_level, occupation, income, registration_status, status, approval_status,
  account_status, subscription_tier, is_dummy, photo_approved, is_banned, is_agent, is_out_of_caste, report_count,
  house_name, blood_group, height_cm, weight_kg, taluk, post_office, pincode, family_details, hobbies
) VALUES (
  '84d22bdb-9620-4d88-b88c-b2e9e540d9df', now(), now(), '+919900010028', 'dummy_boy_29@auth.kurichiyar.com', 'പ്രമോദ് പുത്തൻവീട്', 'പ്രമോദ് പുത്തൻവീട്', 34, 'male', '1992-02-08', 'https://noidreeslytswkmsnmcn.supabase.co/storage/v1/object/public/user_documents/profile_photos/placeholder_male.png',
  'എരിശേരി (ചേരള)', 'കുണ്ടര (കുണ്ടര മൂല)', 50, 11, 'വയനാട്', 'Kerala',
  'ഞാൻ വയനാട്ടിൽ നിന്നുള്ള ഒരു ലളിതജീവിതം നയിക്കുന്ന ആളാണ്. കൃഷിയും ജോലിയിലുമാണ് താല്പര്യം. നല്ലൊരു കുടുംബജീവിതം ആഗ്രഹിക്കുന്നു.', 'എം.സി.എ', 'സർക്കാർ ജീവനക്കാരൻ', '1 ലക്ഷം രൂപ', 'live', 'APPROVED', 'Approved',
  'adminReview', 'Free', true, true, false, false, false, 0,
  'പുത്തൻവീട്', 'B-', 171, 58, 'വൈത്തിരി', 'മീനങ്ങാടി', '673775', 'മാതാവും പിതാവും അടങ്ങുന്ന സന്തുഷ്ട കുടുംബം.', '["വായിക്കുക", "കൃഷി ചെയ്യുക", "യാത്ര ചെയ്യുക"]'
);
INSERT INTO public.kurichiyar_profiles (
  id, created_at, updated_at, phone, email, full_name, name, age, gender, dob, photo_url,
  father_tharavadu, mother_tharavadu, father_clan_id, mother_clan_id, district, state,
  about_me, education_level, occupation, income, registration_status, status, approval_status,
  account_status, subscription_tier, is_dummy, photo_approved, is_banned, is_agent, is_out_of_caste, report_count,
  house_name, blood_group, height_cm, weight_kg, taluk, post_office, pincode, family_details, hobbies
) VALUES (
  '728538c0-b300-41ed-8113-6582318e19b6', now(), now(), '+919900010029', 'dummy_boy_30@auth.kurichiyar.com', 'സന്തോഷ് വടക്കേവീട്', 'സന്തോഷ് വടക്കേവീട്', 23, 'male', '2002-11-07', 'https://noidreeslytswkmsnmcn.supabase.co/storage/v1/object/public/user_documents/profile_photos/placeholder_male.png',
  'കല്ലിയോടൻ (കല്ലിയോട്ട്)', 'ആനി തലക്കര (ആന്നി)', 9, 31, 'കണ്ണൂർ', 'Kerala',
  'സർക്കാർ ജോലി ചെയ്യുന്നു. മാതാപിതാക്കളോടൊപ്പം വയനാട്ടിലാണ് താമസം. കുടുംബസ്നേഹമുള്ള ഒരു പങ്കാളിയെ തേടുന്നു.', 'ബി.എസ്.സി. ബിരുദം', 'തയ്യൽ ജോലി', '3 ലക്ഷം രൂപ', 'live', 'APPROVED', 'Approved',
  'adminReview', 'Free', true, true, false, false, false, 0,
  'വടക്കേവീട്', 'A-', 182, 74, 'തലശ്ശേരി', 'പേരാവൂർ', '673570', 'മാതാവും പിതാവും അടങ്ങുന്ന സന്തുഷ്ട കുടുംബം.', '["വായിക്കുക", "കൃഷി ചെയ്യുക", "യാത്ര ചെയ്യുക"]'
);
INSERT INTO public.kurichiyar_profiles (
  id, created_at, updated_at, phone, email, full_name, name, age, gender, dob, photo_url,
  father_tharavadu, mother_tharavadu, father_clan_id, mother_clan_id, district, state,
  about_me, education_level, occupation, income, registration_status, status, approval_status,
  account_status, subscription_tier, is_dummy, photo_approved, is_banned, is_agent, is_out_of_caste, report_count,
  house_name, blood_group, height_cm, weight_kg, taluk, post_office, pincode, family_details, hobbies
) VALUES (
  '45a91ff8-db5f-41a7-8786-8adf7b6a68a7', now(), now(), '+919900010030', 'dummy_boy_31@auth.kurichiyar.com', 'ഹരിദാസൻ കുനിയിൽ', 'ഹരിദാസൻ കുനിയിൽ', 34, 'male', '1992-05-29', 'https://noidreeslytswkmsnmcn.supabase.co/storage/v1/object/public/user_documents/profile_photos/placeholder_male.png',
  'കരിമ്പിച്ചി (കോടങ്ങേല)', 'നെല്ലേരി മരടി (മരടി നെല്ലേരി)', 28, 2, 'കണ്ണൂർ', 'Kerala',
  'വിദ്യാഭ്യാസമുള്ളതും ലളിതമായ സ്വഭാവമുള്ളതുമായ ഒരു ജീവിതപങ്കാളിയെ ആഗ്രഹിക്കുന്നു. പരസ്പരം മനസ്സിലാക്കി ജീവിക്കാൻ കഴിയണം.', 'എം.എസ്.സി. ബിരുദം', 'സ്റ്റാഫ് നഴ്സ്', '3 ലക്ഷം രൂപ', 'live', 'APPROVED', 'Approved',
  'adminReview', 'Free', true, true, false, false, false, 0,
  'കുനിയിൽ', 'A+', 178, 74, 'തലശ്ശേരി', 'പേരാവൂർ', '673366', 'മാതാവും പിതാവും അടങ്ങുന്ന സന്തുഷ്ട കുടുംബം.', '["വായിക്കുക", "കൃഷി ചെയ്യുക", "യാത്ര ചെയ്യുക"]'
);
INSERT INTO public.kurichiyar_profiles (
  id, created_at, updated_at, phone, email, full_name, name, age, gender, dob, photo_url,
  father_tharavadu, mother_tharavadu, father_clan_id, mother_clan_id, district, state,
  about_me, education_level, occupation, income, registration_status, status, approval_status,
  account_status, subscription_tier, is_dummy, photo_approved, is_banned, is_agent, is_out_of_caste, report_count,
  house_name, blood_group, height_cm, weight_kg, taluk, post_office, pincode, family_details, hobbies
) VALUES (
  '91627f6b-3ad4-4817-a95a-5939eb1b7de9', now(), now(), '+919900010031', 'dummy_boy_32@auth.kurichiyar.com', 'സുകുമാരൻ പടിഞ്ഞാറേവീട്', 'സുകുമാരൻ പടിഞ്ഞാറേവീട്', 33, 'male', '1992-10-11', 'https://noidreeslytswkmsnmcn.supabase.co/storage/v1/object/public/user_documents/profile_photos/placeholder_male.png',
  'പടനി (കുഴികണ്ടം)', 'കൂടൻ (വളമടക്കിൽ)', 53, 12, 'കണ്ണൂർ', 'Kerala',
  'ബിസിനസ്സ് ചെയ്യുന്നു. മാതാപിതാക്കളെ സ്നേഹത്തോടെ നോക്കുന്ന, നല്ലൊരു സ്വഭാവമുള്ള കുട്ടിയെ വിവാഹം കഴിക്കാൻ താല്പര്യമുണ്ട്.', 'പ്ലസ് ടു', 'തയ്യൽ ജോലി', '1 ലക്ഷം രൂപ', 'live', 'APPROVED', 'Approved',
  'adminReview', 'Free', true, true, false, false, false, 0,
  'പടിഞ്ഞാറേവീട്', 'A-', 180, 57, 'തളിപ്പറമ്പ്', 'കേളകം', '673986', 'മാതാവും പിതാവും അടങ്ങുന്ന സന്തുഷ്ട കുടുംബം.', '["വായിക്കുക", "കൃഷി ചെയ്യുക", "യാത്ര ചെയ്യുക"]'
);
INSERT INTO public.kurichiyar_profiles (
  id, created_at, updated_at, phone, email, full_name, name, age, gender, dob, photo_url,
  father_tharavadu, mother_tharavadu, father_clan_id, mother_clan_id, district, state,
  about_me, education_level, occupation, income, registration_status, status, approval_status,
  account_status, subscription_tier, is_dummy, photo_approved, is_banned, is_agent, is_out_of_caste, report_count,
  house_name, blood_group, height_cm, weight_kg, taluk, post_office, pincode, family_details, hobbies
) VALUES (
  '8b50311a-d2b9-4ca6-907b-8f964bc7e841', now(), now(), '+919900010032', 'dummy_boy_33@auth.kurichiyar.com', 'ഭാസ്കരൻ തെക്കേവീട്', 'ഭാസ്കരൻ തെക്കേവീട്', 25, 'male', '2000-08-05', 'https://noidreeslytswkmsnmcn.supabase.co/storage/v1/object/public/user_documents/profile_photos/placeholder_male.png',
  'ചേലപ്പേരോൻ (ഈരനകൊല്ലി)', 'പുച്ചിയേരി (ചായിമ്മൽ)', 57, 10, 'കണ്ണൂർ', 'Kerala',
  'ബിസിനസ്സ് ചെയ്യുന്നു. മാതാപിതാക്കളെ സ്നേഹത്തോടെ നോക്കുന്ന, നല്ലൊരു സ്വഭാവമുള്ള കുട്ടിയെ വിവാഹം കഴിക്കാൻ താല്പര്യമുണ്ട്.', 'ബി.കോം ബിരുദം', 'സർക്കാർ ജീവനക്കാരൻ', '2 ലക്ഷം രൂപ', 'live', 'APPROVED', 'Approved',
  'adminReview', 'Free', true, true, false, false, false, 0,
  'തെക്കേവീട്', 'B-', 181, 60, 'ഇരിട്ടി', 'പേരാവൂർ', '673127', 'മാതാവും പിതാവും അടങ്ങുന്ന സന്തുഷ്ട കുടുംബം.', '["വായിക്കുക", "കൃഷി ചെയ്യുക", "യാത്ര ചെയ്യുക"]'
);
INSERT INTO public.kurichiyar_profiles (
  id, created_at, updated_at, phone, email, full_name, name, age, gender, dob, photo_url,
  father_tharavadu, mother_tharavadu, father_clan_id, mother_clan_id, district, state,
  about_me, education_level, occupation, income, registration_status, status, approval_status,
  account_status, subscription_tier, is_dummy, photo_approved, is_banned, is_agent, is_out_of_caste, report_count,
  house_name, blood_group, height_cm, weight_kg, taluk, post_office, pincode, family_details, hobbies
) VALUES (
  '4548b157-2440-44af-9aee-aca67ded68f5', now(), now(), '+919900010033', 'dummy_boy_34@auth.kurichiyar.com', 'വേണുഗോപാൽ താഴെവീട്', 'വേണുഗോപാൽ താഴെവീട്', 33, 'male', '1993-01-08', 'https://noidreeslytswkmsnmcn.supabase.co/storage/v1/object/public/user_documents/profile_photos/placeholder_male.png',
  'കുറ്റിയോട്ട് കുറ്റിയോടൻ (കുറ്റിയോട്ട്)', 'പെരലാഞ്ചി (മുതുവട്ടിൽ)', 19, 42, 'വയനാട്', 'Kerala',
  'സർക്കാർ ജോലി ചെയ്യുന്നു. മാതാപിതാക്കളോടൊപ്പം വയനാട്ടിലാണ് താമസം. കുടുംബസ്നേഹമുള്ള ഒരു പങ്കാളിയെ തേടുന്നു.', 'ബി.എസ്.സി. ബിരുദം', 'കൃഷി', '3 ലക്ഷം രൂപ', 'live', 'APPROVED', 'Approved',
  'adminReview', 'Free', true, true, false, false, false, 0,
  'താഴെവീട്', 'A+', 163, 71, 'സുൽത്താൻ ബത്തേരി', 'മീനങ്ങാടി', '673111', 'മാതാവും പിതാവും അടങ്ങുന്ന സന്തുഷ്ട കുടുംബം.', '["വായിക്കുക", "കൃഷി ചെയ്യുക", "യാത്ര ചെയ്യുക"]'
);
INSERT INTO public.kurichiyar_profiles (
  id, created_at, updated_at, phone, email, full_name, name, age, gender, dob, photo_url,
  father_tharavadu, mother_tharavadu, father_clan_id, mother_clan_id, district, state,
  about_me, education_level, occupation, income, registration_status, status, approval_status,
  account_status, subscription_tier, is_dummy, photo_approved, is_banned, is_agent, is_out_of_caste, report_count,
  house_name, blood_group, height_cm, weight_kg, taluk, post_office, pincode, family_details, hobbies
) VALUES (
  '79c5bb3e-d972-472f-8adb-c75b9f2007f6', now(), now(), '+919900010034', 'dummy_boy_35@auth.kurichiyar.com', 'ഗംഗാധരൻ കുനിയിൽ', 'ഗംഗാധരൻ കുനിയിൽ', 26, 'male', '2000-05-21', 'https://noidreeslytswkmsnmcn.supabase.co/storage/v1/object/public/user_documents/profile_photos/placeholder_male.png',
  'കൊടുമ തലക്കര (കെടുംമയിൽ)', 'ചെരൂല് (മേനരത്ത്)', 33, 49, 'കോഴിക്കോട്', 'Kerala',
  'വിദ്യാഭ്യാസമുള്ളതും ലളിതമായ സ്വഭാവമുള്ളതുമായ ഒരു ജീവിതപങ്കാളിയെ ആഗ്രഹിക്കുന്നു. പരസ്പരം മനസ്സിലാക്കി ജീവിക്കാൻ കഴിയണം.', 'ബി.കോം ബിരുദം', 'അധ്യാപകൻ', '1 ലക്ഷം രൂപ', 'live', 'APPROVED', 'Approved',
  'adminReview', 'Free', true, true, false, false, false, 0,
  'കുനിയിൽ', 'AB+', 178, 55, 'താമരശ്ശേരി', 'ബാലുശ്ശേരി', '673681', 'മാതാവും പിതാവും അടങ്ങുന്ന സന്തുഷ്ട കുടുംബം.', '["വായിക്കുക", "കൃഷി ചെയ്യുക", "യാത്ര ചെയ്യുക"]'
);
INSERT INTO public.kurichiyar_profiles (
  id, created_at, updated_at, phone, email, full_name, name, age, gender, dob, photo_url,
  father_tharavadu, mother_tharavadu, father_clan_id, mother_clan_id, district, state,
  about_me, education_level, occupation, income, registration_status, status, approval_status,
  account_status, subscription_tier, is_dummy, photo_approved, is_banned, is_agent, is_out_of_caste, report_count,
  house_name, blood_group, height_cm, weight_kg, taluk, post_office, pincode, family_details, hobbies
) VALUES (
  '24f1fc20-aae9-4454-9baa-baefeb7950e3', now(), now(), '+919900010035', 'dummy_boy_36@auth.kurichiyar.com', 'രാധാകൃഷ്ണൻ ഓലിക്കൽ', 'രാധാകൃഷ്ണൻ ഓലിക്കൽ', 26, 'male', '1999-10-18', 'https://noidreeslytswkmsnmcn.supabase.co/storage/v1/object/public/user_documents/profile_photos/placeholder_male.png',
  'നെല്ലുകുടിയൻ (കാക്കോത്തറ)', 'ആനി തലക്കര (ആന്നി)', 4, 31, 'വയനാട്', 'Kerala',
  'ഞാൻ വയനാട്ടിൽ നിന്നുള്ള ഒരു ലളിതജീവിതം നയിക്കുന്ന ആളാണ്. കൃഷിയും ജോലിയിലുമാണ് താല്പര്യം. നല്ലൊരു കുടുംബജീവിതം ആഗ്രഹിക്കുന്നു.', 'എം.എസ്.സി. ബിരുദം', 'സർക്കാർ ജീവനക്കാരൻ', '4 ലക്ഷം രൂപ', 'live', 'APPROVED', 'Approved',
  'adminReview', 'Free', true, true, false, false, false, 0,
  'ഓലിക്കൽ', 'AB+', 183, 62, 'സുൽത്താൻ ബത്തേരി', 'അമ്പലക്കുന്ന്', '673490', 'മാതാവും പിതാവും അടങ്ങുന്ന സന്തുഷ്ട കുടുംബം.', '["വായിക്കുക", "കൃഷി ചെയ്യുക", "യാത്ര ചെയ്യുക"]'
);
INSERT INTO public.kurichiyar_profiles (
  id, created_at, updated_at, phone, email, full_name, name, age, gender, dob, photo_url,
  father_tharavadu, mother_tharavadu, father_clan_id, mother_clan_id, district, state,
  about_me, education_level, occupation, income, registration_status, status, approval_status,
  account_status, subscription_tier, is_dummy, photo_approved, is_banned, is_agent, is_out_of_caste, report_count,
  house_name, blood_group, height_cm, weight_kg, taluk, post_office, pincode, family_details, hobbies
) VALUES (
  '68f34e9e-00e4-4fc7-8556-22f83fd2e5a8', now(), now(), '+919900010036', 'dummy_boy_37@auth.kurichiyar.com', 'മോഹൻദാസ് കുനിയിൽ', 'മോഹൻദാസ് കുനിയിൽ', 29, 'male', '1996-10-07', 'https://noidreeslytswkmsnmcn.supabase.co/storage/v1/object/public/user_documents/profile_photos/placeholder_male.png',
  'കുക്കോടൻ (കുക്കോട്ടിൽ)', 'ചാൽപ്പ (പിൽപ്പിടി - പള്ളിയറ)', 55, 52, 'കണ്ണൂർ', 'Kerala',
  'വിദ്യാഭ്യാസമുള്ളതും ലളിതമായ സ്വഭാവമുള്ളതുമായ ഒരു ജീവിതപങ്കാളിയെ ആഗ്രഹിക്കുന്നു. പരസ്പരം മനസ്സിലാക്കി ജീവിക്കാൻ കഴിയണം.', 'ബി.എ. ബിരുദം', 'софтവെയർ എഞ്ചിനീയർ', '3 ലക്ഷം രൂപ', 'live', 'APPROVED', 'Approved',
  'adminReview', 'Free', true, true, false, false, false, 0,
  'കുനിയിൽ', 'O+', 182, 67, 'തലശ്ശേരി', 'കേളകം', '673486', 'മാതാവും പിതാവും അടങ്ങുന്ന സന്തുഷ്ട കുടുംബം.', '["വായിക്കുക", "കൃഷി ചെയ്യുക", "യാത്ര ചെയ്യുക"]'
);
INSERT INTO public.kurichiyar_profiles (
  id, created_at, updated_at, phone, email, full_name, name, age, gender, dob, photo_url,
  father_tharavadu, mother_tharavadu, father_clan_id, mother_clan_id, district, state,
  about_me, education_level, occupation, income, registration_status, status, approval_status,
  account_status, subscription_tier, is_dummy, photo_approved, is_banned, is_agent, is_out_of_caste, report_count,
  house_name, blood_group, height_cm, weight_kg, taluk, post_office, pincode, family_details, hobbies
) VALUES (
  '27932b2f-ac26-4e1a-a995-0c419e881797', now(), now(), '+919900010037', 'dummy_boy_38@auth.kurichiyar.com', 'പ്രകാശൻ വടക്കേവീട്', 'പ്രകാശൻ വടക്കേവീട്', 32, 'male', '1994-06-11', 'https://noidreeslytswkmsnmcn.supabase.co/storage/v1/object/public/user_documents/profile_photos/placeholder_male.png',
  'പടനി (കുഴികണ്ടം)', 'പെരലാഞ്ചി (മുതുവട്ടിൽ)', 53, 42, 'കണ്ണൂർ', 'Kerala',
  'സ്വകാര്യ സ്ഥാപനത്തിൽ ജോലി ചെയ്യുന്നു. കുടുംബത്തിന് വലിയ പ്രാധാന്യം നൽകുന്നു. യോജിച്ച ഒരു പെൺകുട്ടിയെ തേടുന്നു.', 'എം.സി.എ', 'അധ്യാപകൻ', '4 ലക്ഷം രൂപ', 'live', 'APPROVED', 'Approved',
  'adminReview', 'Free', true, true, false, false, false, 0,
  'വടക്കേവീട്', 'B+', 182, 56, 'തലശ്ശേരി', 'പേരാവൂർ', '673391', 'മാതാവും പിതാവും അടങ്ങുന്ന സന്തുഷ്ട കുടുംബം.', '["വായിക്കുക", "കൃഷി ചെയ്യുക", "യാത്ര ചെയ്യുക"]'
);
INSERT INTO public.kurichiyar_profiles (
  id, created_at, updated_at, phone, email, full_name, name, age, gender, dob, photo_url,
  father_tharavadu, mother_tharavadu, father_clan_id, mother_clan_id, district, state,
  about_me, education_level, occupation, income, registration_status, status, approval_status,
  account_status, subscription_tier, is_dummy, photo_approved, is_banned, is_agent, is_out_of_caste, report_count,
  house_name, blood_group, height_cm, weight_kg, taluk, post_office, pincode, family_details, hobbies
) VALUES (
  '20a91055-01e1-463c-9d79-469a5885feca', now(), now(), '+919900010038', 'dummy_boy_39@auth.kurichiyar.com', 'ജയരാജൻ മീത്തൽ', 'ജയരാജൻ മീത്തൽ', 34, 'male', '1991-11-01', 'https://noidreeslytswkmsnmcn.supabase.co/storage/v1/object/public/user_documents/profile_photos/placeholder_male.png',
  'വെണ്ണിയോറ (വെണ്ണിയോറ)', 'കുന്നംകൊലൻ (ചേരിമ്മൽ)', 23, 13, 'കോഴിക്കോട്', 'Kerala',
  'സർക്കാർ ജോലി ചെയ്യുന്നു. മാതാപിതാക്കളോടൊപ്പം വയനാട്ടിലാണ് താമസം. കുടുംബസ്നേഹമുള്ള ഒരു പങ്കാളിയെ തേടുന്നു.', 'ബി.ടെക് എഞ്ചിനീയറിംഗ്', 'തയ്യൽ ജോലി', '1 ലക്ഷം രൂപ', 'live', 'APPROVED', 'Approved',
  'adminReview', 'Free', true, true, false, false, false, 0,
  'മീത്തൽ', 'O+', 166, 66, 'കൊയിലാണ്ടി', 'പേരാമ്പ്ര', '673201', 'മാതാവും പിതാവും അടങ്ങുന്ന സന്തുഷ്ട കുടുംബം.', '["വായിക്കുക", "കൃഷി ചെയ്യുക", "യാത്ര ചെയ്യുക"]'
);
INSERT INTO public.kurichiyar_profiles (
  id, created_at, updated_at, phone, email, full_name, name, age, gender, dob, photo_url,
  father_tharavadu, mother_tharavadu, father_clan_id, mother_clan_id, district, state,
  about_me, education_level, occupation, income, registration_status, status, approval_status,
  account_status, subscription_tier, is_dummy, photo_approved, is_banned, is_agent, is_out_of_caste, report_count,
  house_name, blood_group, height_cm, weight_kg, taluk, post_office, pincode, family_details, hobbies
) VALUES (
  '5046e7de-e1aa-436b-8c9a-7f059f045289', now(), now(), '+919900010039', 'dummy_boy_40@auth.kurichiyar.com', 'രാജീവൻ എടത്തറ', 'രാജീവൻ എടത്തറ', 26, 'male', '1999-09-13', 'https://noidreeslytswkmsnmcn.supabase.co/storage/v1/object/public/user_documents/profile_photos/placeholder_male.png',
  'ചെന്നലര കുറ്റിയോടൻ (ചെന്നലര)', 'ചേലപ്പേരോൻ (ഈരനകൊല്ലി)', 18, 57, 'കോഴിക്കോട്', 'Kerala',
  'ഞാൻ വയനാട്ടിൽ നിന്നുള്ള ഒരു ലളിതജീവിതം നയിക്കുന്ന ആളാണ്. കൃഷിയും ജോലിയിലുമാണ് താല്പര്യം. നല്ലൊരു കുടുംബജീവിതം ആഗ്രഹിക്കുന്നു.', 'എം.എസ്.സി. ബിരുദം', 'തയ്യൽ ജോലി', '4 ലക്ഷം രൂപ', 'live', 'APPROVED', 'Approved',
  'adminReview', 'Free', true, true, false, false, false, 0,
  'എടത്തറ', 'B+', 173, 65, 'വടകര', 'കോടുവള്ളി', '673729', 'മാതാവും പിതാവും അടങ്ങുന്ന സന്തുഷ്ട കുടുംബം.', '["വായിക്കുക", "കൃഷി ചെയ്യുക", "യാത്ര ചെയ്യുക"]'
);
INSERT INTO public.kurichiyar_profiles (
  id, created_at, updated_at, phone, email, full_name, name, age, gender, dob, photo_url,
  father_tharavadu, mother_tharavadu, father_clan_id, mother_clan_id, district, state,
  about_me, education_level, occupation, income, registration_status, status, approval_status,
  account_status, subscription_tier, is_dummy, photo_approved, is_banned, is_agent, is_out_of_caste, report_count,
  house_name, blood_group, height_cm, weight_kg, taluk, post_office, pincode, family_details, hobbies
) VALUES (
  '7575f9f3-2488-4045-bf0e-b0050c32c9ee', now(), now(), '+919900010040', 'dummy_boy_41@auth.kurichiyar.com', 'വിനോദ് പടിഞ്ഞാറേവീട്', 'വിനോദ് പടിഞ്ഞാറേവീട്', 32, 'male', '1994-02-03', 'https://noidreeslytswkmsnmcn.supabase.co/storage/v1/object/public/user_documents/profile_photos/placeholder_male.png',
  'അതിരും കൊലൻ (പঞ্চേരി)', 'ചെന്നലര കുറ്റിയോടൻ (ചെന്നലര)', 37, 18, 'കോഴിക്കോട്', 'Kerala',
  'ഞാൻ വയനാട്ടിൽ നിന്നുള്ള ഒരു ലളിതജീവിതം നയിക്കുന്ന ആളാണ്. കൃഷിയും ജോലിയിലുമാണ് താല്പര്യം. നല്ലൊരു കുടുംബജീവിതം ആഗ്രഹിക്കുന്നു.', 'എം.സി.എ', 'സ്റ്റാഫ് നഴ്സ്', '4 ലക്ഷം രൂപ', 'live', 'APPROVED', 'Approved',
  'adminReview', 'Free', true, true, false, false, false, 0,
  'പടിഞ്ഞാറേവീട്', 'A-', 165, 59, 'കൊയിലാണ്ടി', 'പേരാമ്പ്ര', '673230', 'മാതാവും പിതാവും അടങ്ങുന്ന സന്തുഷ്ട കുടുംബം.', '["വായിക്കുക", "കൃഷി ചെയ്യുക", "യാത്ര ചെയ്യുക"]'
);
INSERT INTO public.kurichiyar_profiles (
  id, created_at, updated_at, phone, email, full_name, name, age, gender, dob, photo_url,
  father_tharavadu, mother_tharavadu, father_clan_id, mother_clan_id, district, state,
  about_me, education_level, occupation, income, registration_status, status, approval_status,
  account_status, subscription_tier, is_dummy, photo_approved, is_banned, is_agent, is_out_of_caste, report_count,
  house_name, blood_group, height_cm, weight_kg, taluk, post_office, pincode, family_details, hobbies
) VALUES (
  '26ffe558-540c-4e5c-b6cf-d9fdc5e4f237', now(), now(), '+919900010041', 'dummy_boy_42@auth.kurichiyar.com', 'ജയചന്ദ്രൻ കോട്ടയിൽ', 'ജയചന്ദ്രൻ കോട്ടയിൽ', 23, 'male', '2002-09-08', 'https://noidreeslytswkmsnmcn.supabase.co/storage/v1/object/public/user_documents/profile_photos/placeholder_male.png',
  'മൂത്തേടൻ (മൂത്തേടത്ത്)', 'വെണ്ണിയോറ (വെണ്ണിയോറ)', 27, 23, 'കോഴിക്കോട്', 'Kerala',
  'വിദ്യാഭ്യാസമുള്ളതും ലളിതമായ സ്വഭാവമുള്ളതുമായ ഒരു ജീവിതപങ്കാളിയെ ആഗ്രഹിക്കുന്നു. പരസ്പരം മനസ്സിലാക്കി ജീവിക്കാൻ കഴിയണം.', 'പ്ലസ് ടു', 'സർക്കാർ ജീവനക്കാരൻ', '5 ലക്ഷം രൂപ', 'live', 'APPROVED', 'Approved',
  'adminReview', 'Free', true, true, false, false, false, 0,
  'കോട്ടയിൽ', 'B-', 184, 67, 'വടകര', 'കോടുവള്ളി', '673637', 'മാതാവും പിതാവും അടങ്ങുന്ന സന്തുഷ്ട കുടുംബം.', '["വായിക്കുക", "കൃഷി ചെയ്യുക", "യാത്ര ചെയ്യുക"]'
);
INSERT INTO public.kurichiyar_profiles (
  id, created_at, updated_at, phone, email, full_name, name, age, gender, dob, photo_url,
  father_tharavadu, mother_tharavadu, father_clan_id, mother_clan_id, district, state,
  about_me, education_level, occupation, income, registration_status, status, approval_status,
  account_status, subscription_tier, is_dummy, photo_approved, is_banned, is_agent, is_out_of_caste, report_count,
  house_name, blood_group, height_cm, weight_kg, taluk, post_office, pincode, family_details, hobbies
) VALUES (
  '423797cb-ef2b-4c54-ba84-326dc9a95781', now(), now(), '+919900010042', 'dummy_boy_43@auth.kurichiyar.com', 'സുനിൽ തെക്കേവീട്', 'സുനിൽ തെക്കേവീട്', 30, 'male', '1995-11-27', 'https://noidreeslytswkmsnmcn.supabase.co/storage/v1/object/public/user_documents/profile_photos/placeholder_male.png',
  'ഇടുണി (കിഴക്കുംപാട്ട് - ഇടുണി)', 'കുക്കോടൻ (കുക്കോട്ടിൽ)', 44, 55, 'കണ്ണൂർ', 'Kerala',
  'സർക്കാർ ജോലി ചെയ്യുന്നു. മാതാപിതാക്കളോടൊപ്പം വയനാട്ടിലാണ് താമസം. കുടുംബസ്നേഹമുള്ള ഒരു പങ്കാളിയെ തേടുന്നു.', 'എം.സി.എ', 'വ്യാപാരി', '3 ലക്ഷം രൂപ', 'live', 'APPROVED', 'Approved',
  'adminReview', 'Free', true, true, false, false, false, 0,
  'തെക്കേവീട്', 'AB+', 179, 69, 'തളിപ്പറമ്പ്', 'കേളകം', '673260', 'മാതാവും പിതാവും അടങ്ങുന്ന സന്തുഷ്ട കുടുംബം.', '["വായിക്കുക", "കൃഷി ചെയ്യുക", "യാത്ര ചെയ്യുക"]'
);
INSERT INTO public.kurichiyar_profiles (
  id, created_at, updated_at, phone, email, full_name, name, age, gender, dob, photo_url,
  father_tharavadu, mother_tharavadu, father_clan_id, mother_clan_id, district, state,
  about_me, education_level, occupation, income, registration_status, status, approval_status,
  account_status, subscription_tier, is_dummy, photo_approved, is_banned, is_agent, is_out_of_caste, report_count,
  house_name, blood_group, height_cm, weight_kg, taluk, post_office, pincode, family_details, hobbies
) VALUES (
  '4c801080-2806-4248-9aee-bc00d54cf147', now(), now(), '+919900010043', 'dummy_boy_44@auth.kurichiyar.com', 'അനിലി കുനിയിൽ', 'അനിലി കുനിയിൽ', 30, 'male', '1995-11-17', 'https://noidreeslytswkmsnmcn.supabase.co/storage/v1/object/public/user_documents/profile_photos/placeholder_male.png',
  'ചേരക്കര (കോലിമൂല)', 'പുതിയിടം ചമ്മിയേരി (പുതിയിടം)', 8, 46, 'കോഴിക്കോട്', 'Kerala',
  'സ്വകാര്യ സ്ഥാപനത്തിൽ ജോലി ചെയ്യുന്നു. കുടുംബത്തിന് വലിയ പ്രാധാന്യം നൽകുന്നു. യോജിച്ച ഒരു പെൺകുട്ടിയെ തേടുന്നു.', 'എം.എസ്.സി. ബിരുദം', 'സ്റ്റാഫ് നഴ്സ്', '4 ലക്ഷം രൂപ', 'live', 'APPROVED', 'Approved',
  'adminReview', 'Free', true, true, false, false, false, 0,
  'കുനിയിൽ', 'A-', 170, 62, 'താമരശ്ശേരി', 'പേരാമ്പ്ര', '673279', 'മാതാവും പിതാവും അടങ്ങുന്ന സന്തുഷ്ട കുടുംബം.', '["വായിക്കുക", "കൃഷി ചെയ്യുക", "യാത്ര ചെയ്യുക"]'
);
INSERT INTO public.kurichiyar_profiles (
  id, created_at, updated_at, phone, email, full_name, name, age, gender, dob, photo_url,
  father_tharavadu, mother_tharavadu, father_clan_id, mother_clan_id, district, state,
  about_me, education_level, occupation, income, registration_status, status, approval_status,
  account_status, subscription_tier, is_dummy, photo_approved, is_banned, is_agent, is_out_of_caste, report_count,
  house_name, blood_group, height_cm, weight_kg, taluk, post_office, pincode, family_details, hobbies
) VALUES (
  'f485ffca-f90e-4738-b94e-8795e0671f4e', now(), now(), '+919900010044', 'dummy_boy_45@auth.kurichiyar.com', 'സതീശൻ വലിപ്പവീട്', 'സതീശൻ വലിപ്പവീട്', 34, 'male', '1992-02-25', 'https://noidreeslytswkmsnmcn.supabase.co/storage/v1/object/public/user_documents/profile_photos/placeholder_male.png',
  'ചെറുമ്പാലൻ (കാക്കൻ ചിറ)', 'കൊന്നിയോടൻ (കൊന്നിയോട്ട്)', 24, 39, 'കണ്ണൂർ', 'Kerala',
  'സ്വകാര്യ സ്ഥാപനത്തിൽ ജോലി ചെയ്യുന്നു. കുടുംബത്തിന് വലിയ പ്രാധാന്യം നൽകുന്നു. യോജിച്ച ഒരു പെൺകുട്ടിയെ തേടുന്നു.', 'ബി.ടെക് എഞ്ചിനീയറിംഗ്', 'സർക്കാർ ജീവനക്കാരൻ', '4 ലക്ഷം രൂപ', 'live', 'APPROVED', 'Approved',
  'adminReview', 'Free', true, true, false, false, false, 0,
  'വലിപ്പവീട്', 'B-', 173, 66, 'തളിപ്പറമ്പ്', 'പേരാവൂർ', '673335', 'മാതാവും പിതാവും അടങ്ങുന്ന സന്തുഷ്ട കുടുംബം.', '["വായിക്കുക", "കൃഷി ചെയ്യുക", "യാത്ര ചെയ്യുക"]'
);
INSERT INTO public.kurichiyar_profiles (
  id, created_at, updated_at, phone, email, full_name, name, age, gender, dob, photo_url,
  father_tharavadu, mother_tharavadu, father_clan_id, mother_clan_id, district, state,
  about_me, education_level, occupation, income, registration_status, status, approval_status,
  account_status, subscription_tier, is_dummy, photo_approved, is_banned, is_agent, is_out_of_caste, report_count,
  house_name, blood_group, height_cm, weight_kg, taluk, post_office, pincode, family_details, hobbies
) VALUES (
  '786381e7-38da-4ff2-bd01-d3c11419750f', now(), now(), '+919900010045', 'dummy_boy_46@auth.kurichiyar.com', 'സുധീഷ് കുനിയിൽ', 'സുധീഷ് കുനിയിൽ', 29, 'male', '1997-02-22', 'https://noidreeslytswkmsnmcn.supabase.co/storage/v1/object/public/user_documents/profile_photos/placeholder_male.png',
  'എടമന (എടമന)', 'കൊടിയേരി (പൂലായ്ക്കൽ)', 43, 26, 'കണ്ണൂർ', 'Kerala',
  'ഞാൻ വയനാട്ടിൽ നിന്നുള്ള ഒരു ലളിതജീവിതം നയിക്കുന്ന ആളാണ്. കൃഷിയും ജോലിയിലുമാണ് താല്പര്യം. നല്ലൊരു കുടുംബജീവിതം ആഗ്രഹിക്കുന്നു.', 'ബി.എസ്.സി. ബിരുദം', 'തയ്യൽ ജോലി', '5 ലക്ഷം രൂപ', 'live', 'APPROVED', 'Approved',
  'adminReview', 'Free', true, true, false, false, false, 0,
  'കുനിയിൽ', 'B-', 168, 56, 'ഇരിട്ടി', 'മട്ടന്നൂർ', '673313', 'മാതാവും പിതാവും അടങ്ങുന്ന സന്തുഷ്ട കുടുംബം.', '["വായിക്കുക", "കൃഷി ചെയ്യുക", "യാത്ര ചെയ്യുക"]'
);
INSERT INTO public.kurichiyar_profiles (
  id, created_at, updated_at, phone, email, full_name, name, age, gender, dob, photo_url,
  father_tharavadu, mother_tharavadu, father_clan_id, mother_clan_id, district, state,
  about_me, education_level, occupation, income, registration_status, status, approval_status,
  account_status, subscription_tier, is_dummy, photo_approved, is_banned, is_agent, is_out_of_caste, report_count,
  house_name, blood_group, height_cm, weight_kg, taluk, post_office, pincode, family_details, hobbies
) VALUES (
  '8c3411df-f09e-4ce8-9271-a8d750ccb4fd', now(), now(), '+919900010046', 'dummy_boy_47@auth.kurichiyar.com', 'മഹേഷ് കുനിയിൽ', 'മഹേഷ് കുനിയിൽ', 28, 'male', '1998-04-14', 'https://noidreeslytswkmsnmcn.supabase.co/storage/v1/object/public/user_documents/profile_photos/placeholder_male.png',
  'വെണ്ണിയോറ (വെണ്ണിയോറ)', 'ചെന്നാക്കണ്ടൻ വളാടൻ (ഒറ്റമലച്ചി)', 23, 6, 'കോഴിക്കോട്', 'Kerala',
  'സർക്കാർ ജോലി ചെയ്യുന്നു. മാതാപിതാക്കളോടൊപ്പം വയനാട്ടിലാണ് താമസം. കുടുംബസ്നേഹമുള്ള ഒരു പങ്കാളിയെ തേടുന്നു.', 'ജനറൽ നഴ്സിംഗ്', 'софтവെയർ എഞ്ചിനീയർ', '3 ലക്ഷം രൂപ', 'live', 'APPROVED', 'Approved',
  'adminReview', 'Free', true, true, false, false, false, 0,
  'കുനിയിൽ', 'B-', 183, 68, 'താമരശ്ശേരി', 'കോടുവള്ളി', '673361', 'മാതാവും പിതാവും അടങ്ങുന്ന സന്തുഷ്ട കുടുംബം.', '["വായിക്കുക", "കൃഷി ചെയ്യുക", "യാത്ര ചെയ്യുക"]'
);
INSERT INTO public.kurichiyar_profiles (
  id, created_at, updated_at, phone, email, full_name, name, age, gender, dob, photo_url,
  father_tharavadu, mother_tharavadu, father_clan_id, mother_clan_id, district, state,
  about_me, education_level, occupation, income, registration_status, status, approval_status,
  account_status, subscription_tier, is_dummy, photo_approved, is_banned, is_agent, is_out_of_caste, report_count,
  house_name, blood_group, height_cm, weight_kg, taluk, post_office, pincode, family_details, hobbies
) VALUES (
  '973fb2b9-2d66-494c-9b26-5a6aefaaf200', now(), now(), '+919900010047', 'dummy_boy_48@auth.kurichiyar.com', 'അഭിലാഷ് വലിപ്പവീട്', 'അഭിലാഷ് വലിപ്പവീട്', 32, 'male', '1993-08-26', 'https://noidreeslytswkmsnmcn.supabase.co/storage/v1/object/public/user_documents/profile_photos/placeholder_male.png',
  'കുണ്ടര (കുണ്ടര മൂല)', 'നെല്ലേരി മരടി (മരടി നെല്ലേരി)', 11, 2, 'വയനാട്', 'Kerala',
  'സ്വകാര്യ സ്ഥാപനത്തിൽ ജോലി ചെയ്യുന്നു. കുടുംബത്തിന് വലിയ പ്രാധാന്യം നൽകുന്നു. യോജിച്ച ഒരു പെൺകുട്ടിയെ തേടുന്നു.', 'പ്ലസ് ടു', 'തയ്യൽ ജോലി', '1 ലക്ഷം രൂപ', 'live', 'APPROVED', 'Approved',
  'adminReview', 'Free', true, true, false, false, false, 0,
  'വലിപ്പവീട്', 'B+', 160, 61, 'മാനന്തവാടി', 'അമ്പലക്കുന്ന്', '673389', 'മാതാവും പിതാവും അടങ്ങുന്ന സന്തുഷ്ട കുടുംബം.', '["വായിക്കുക", "കൃഷി ചെയ്യുക", "യാത്ര ചെയ്യുക"]'
);
INSERT INTO public.kurichiyar_profiles (
  id, created_at, updated_at, phone, email, full_name, name, age, gender, dob, photo_url,
  father_tharavadu, mother_tharavadu, father_clan_id, mother_clan_id, district, state,
  about_me, education_level, occupation, income, registration_status, status, approval_status,
  account_status, subscription_tier, is_dummy, photo_approved, is_banned, is_agent, is_out_of_caste, report_count,
  house_name, blood_group, height_cm, weight_kg, taluk, post_office, pincode, family_details, hobbies
) VALUES (
  '7a79327c-f145-41c5-84e4-fbf1614b52a8', now(), now(), '+919900010048', 'dummy_boy_49@auth.kurichiyar.com', 'കിരൺ പുത്തൻവീട്', 'കിരൺ പുത്തൻവീട്', 27, 'male', '1998-10-14', 'https://noidreeslytswkmsnmcn.supabase.co/storage/v1/object/public/user_documents/profile_photos/placeholder_male.png',
  'ചേലപ്പേരോൻ (ഈരനകൊല്ലി)', 'ചെന്നാക്കണ്ടൻ വളാടൻ (ഒറ്റമലച്ചി)', 57, 6, 'കണ്ണൂർ', 'Kerala',
  'ഞാൻ വയനാട്ടിൽ നിന്നുള്ള ഒരു ലളിതജീവിതം നയിക്കുന്ന ആളാണ്. കൃഷിയും ജോലിയിലുമാണ് താല്പര്യം. നല്ലൊരു കുടുംബജീവിതം ആഗ്രഹിക്കുന്നു.', 'എം.സി.എ', 'അധ്യാപകൻ', '5 ലക്ഷം രൂപ', 'live', 'APPROVED', 'Approved',
  'adminReview', 'Free', true, true, false, false, false, 0,
  'പുത്തൻവീട്', 'A+', 178, 63, 'ഇരിട്ടി', 'കേളകം', '673294', 'മാതാവും പിതാവും അടങ്ങുന്ന സന്തുഷ്ട കുടുംബം.', '["വായിക്കുക", "കൃഷി ചെയ്യുക", "യാത്ര ചെയ്യുക"]'
);
INSERT INTO public.kurichiyar_profiles (
  id, created_at, updated_at, phone, email, full_name, name, age, gender, dob, photo_url,
  father_tharavadu, mother_tharavadu, father_clan_id, mother_clan_id, district, state,
  about_me, education_level, occupation, income, registration_status, status, approval_status,
  account_status, subscription_tier, is_dummy, photo_approved, is_banned, is_agent, is_out_of_caste, report_count,
  house_name, blood_group, height_cm, weight_kg, taluk, post_office, pincode, family_details, hobbies
) VALUES (
  'dbb968cb-19ca-4ab7-af40-3756394ead53', now(), now(), '+919900010049', 'dummy_boy_50@auth.kurichiyar.com', 'സനൂപ് കുന്നിൻമേൽ', 'സനൂപ് കുന്നിൻമേൽ', 31, 'male', '1995-06-30', 'https://noidreeslytswkmsnmcn.supabase.co/storage/v1/object/public/user_documents/profile_photos/placeholder_male.png',
  'ചെരൂല് (മേനരത്ത്)', 'കൂടൻ (വളമടക്കിൽ)', 49, 12, 'കോഴിക്കോട്', 'Kerala',
  'വിദ്യാഭ്യാസമുള്ളതും ലളിതമായ സ്വഭാവമുള്ളതുമായ ഒരു ജീവിതപങ്കാളിയെ ആഗ്രഹിക്കുന്നു. പരസ്പരം മനസ്സിലാക്കി ജീവിക്കാൻ കഴിയണം.', 'ബി.കോം ബിരുദം', 'വ്യാപാരി', '2 ലക്ഷം രൂപ', 'live', 'APPROVED', 'Approved',
  'adminReview', 'Free', true, true, false, false, false, 0,
  'കുന്നിൻമേൽ', 'A-', 181, 68, 'താമരശ്ശേരി', 'കോടുവള്ളി', '673933', 'മാതാവും പിതാവും അടങ്ങുന്ന സന്തുഷ്ട കുടുംബം.', '["വായിക്കുക", "കൃഷി ചെയ്യുക", "യാത്ര ചെയ്യുക"]'
);
INSERT INTO public.kurichiyar_profiles (
  id, created_at, updated_at, phone, email, full_name, name, age, gender, dob, photo_url,
  father_tharavadu, mother_tharavadu, father_clan_id, mother_clan_id, district, state,
  about_me, education_level, occupation, income, registration_status, status, approval_status,
  account_status, subscription_tier, is_dummy, photo_approved, is_banned, is_agent, is_out_of_caste, report_count,
  house_name, blood_group, height_cm, weight_kg, taluk, post_office, pincode, family_details, hobbies
) VALUES (
  '4c92a8e3-faf0-4eb8-b115-e62b763dcc3f', now(), now(), '+919900010050', 'dummy_boy_51@auth.kurichiyar.com', 'വിഷ്ണു എടക്കുടി', 'വിഷ്ണു എടക്കുടി', 23, 'male', '2003-01-24', 'https://noidreeslytswkmsnmcn.supabase.co/storage/v1/object/public/user_documents/profile_photos/placeholder_male.png',
  'വളാടൻ (ഇല്ലത്തുമൂല)', 'പെരലാഞ്ചി (മുതുവട്ടിൽ)', 5, 42, 'കണ്ണൂർ', 'Kerala',
  'സ്വകാര്യ സ്ഥാപനത്തിൽ ജോലി ചെയ്യുന്നു. കുടുംബത്തിന് വലിയ പ്രാധാന്യം നൽകുന്നു. യോജിച്ച ഒരു പെൺകുട്ടിയെ തേടുന്നു.', 'ബി.എസ്.സി. ബിരുദം', 'ഡ്രൈവർ', '2 ലക്ഷം രൂപ', 'live', 'APPROVED', 'Approved',
  'adminReview', 'Free', true, true, false, false, false, 0,
  'എടക്കുടി', 'O+', 183, 64, 'തളിപ്പറമ്പ്', 'പേരാവൂർ', '673367', 'മാതാവും പിതാവും അടങ്ങുന്ന സന്തുഷ്ട കുടുംബം.', '["വായിക്കുക", "കൃഷി ചെയ്യുക", "യാത്ര ചെയ്യുക"]'
);
INSERT INTO public.kurichiyar_profiles (
  id, created_at, updated_at, phone, email, full_name, name, age, gender, dob, photo_url,
  father_tharavadu, mother_tharavadu, father_clan_id, mother_clan_id, district, state,
  about_me, education_level, occupation, income, registration_status, status, approval_status,
  account_status, subscription_tier, is_dummy, photo_approved, is_banned, is_agent, is_out_of_caste, report_count,
  house_name, blood_group, height_cm, weight_kg, taluk, post_office, pincode, family_details, hobbies
) VALUES (
  'aa2d15dc-5de5-4848-af2d-c3f514d208f8', now(), now(), '+919900010051', 'dummy_boy_52@auth.kurichiyar.com', 'അർജുൻ പാലക്കൽ', 'അർജുൻ പാലക്കൽ', 30, 'male', '1996-01-26', 'https://noidreeslytswkmsnmcn.supabase.co/storage/v1/object/public/user_documents/profile_photos/placeholder_male.png',
  'കുനിമൽ മിലിയാടി (കുനിയമ്മൽ)', 'ചെന്നാക്കണ്ടൻ വളാടൻ (ഒറ്റമലച്ചി)', 35, 6, 'കണ്ണൂർ', 'Kerala',
  'ഞാൻ വയനാട്ടിൽ നിന്നുള്ള ഒരു ലളിതജീവിതം നയിക്കുന്ന ആളാണ്. കൃഷിയും ജോലിയിലുമാണ് താല്പര്യം. നല്ലൊരു കുടുംബജീവിതം ആഗ്രഹിക്കുന്നു.', 'ബി.എ. ബിരുദം', 'സ്വകാര്യ കമ്പനി ജോലി', '3 ലക്ഷം രൂപ', 'live', 'APPROVED', 'Approved',
  'adminReview', 'Free', true, true, false, false, false, 0,
  'പാലക്കൽ', 'A-', 160, 72, 'തലശ്ശേരി', 'പേരാവൂർ', '673560', 'മാതാവും പിതാവും അടങ്ങുന്ന സന്തുഷ്ട കുടുംബം.', '["വായിക്കുക", "കൃഷി ചെയ്യുക", "യാത്ര ചെയ്യുക"]'
);
INSERT INTO public.kurichiyar_profiles (
  id, created_at, updated_at, phone, email, full_name, name, age, gender, dob, photo_url,
  father_tharavadu, mother_tharavadu, father_clan_id, mother_clan_id, district, state,
  about_me, education_level, occupation, income, registration_status, status, approval_status,
  account_status, subscription_tier, is_dummy, photo_approved, is_banned, is_agent, is_out_of_caste, report_count,
  house_name, blood_group, height_cm, weight_kg, taluk, post_office, pincode, family_details, hobbies
) VALUES (
  'adcdca3b-a898-4d31-a209-58537452e477', now(), now(), '+919900010052', 'dummy_boy_53@auth.kurichiyar.com', 'സാരംഗ് മീത്തൽ', 'സാരംഗ് മീത്തൽ', 27, 'male', '1999-05-28', 'https://noidreeslytswkmsnmcn.supabase.co/storage/v1/object/public/user_documents/profile_photos/placeholder_male.png',
  'വേമോത്ത് പുച്ചേരി (വയമോത്ത്)', 'പടനി (കുഴികണ്ടം)', 25, 53, 'കണ്ണൂർ', 'Kerala',
  'സർക്കാർ ജോലി ചെയ്യുന്നു. മാതാപിതാക്കളോടൊപ്പം വയനാട്ടിലാണ് താമസം. കുടുംബസ്നേഹമുള്ള ഒരു പങ്കാളിയെ തേടുന്നു.', 'ബി.കോം ബിരുദം', 'തയ്യൽ ജോലി', '3 ലക്ഷം രൂപ', 'live', 'APPROVED', 'Approved',
  'adminReview', 'Free', true, true, false, false, false, 0,
  'മീത്തൽ', 'A+', 170, 70, 'തലശ്ശേരി', 'മട്ടന്നൂർ', '673557', 'മാതാവും പിതാവും അടങ്ങുന്ന സന്തുഷ്ട കുടുംബം.', '["വായിക്കുക", "കൃഷി ചെയ്യുക", "യാത്ര ചെയ്യുക"]'
);
INSERT INTO public.kurichiyar_profiles (
  id, created_at, updated_at, phone, email, full_name, name, age, gender, dob, photo_url,
  father_tharavadu, mother_tharavadu, father_clan_id, mother_clan_id, district, state,
  about_me, education_level, occupation, income, registration_status, status, approval_status,
  account_status, subscription_tier, is_dummy, photo_approved, is_banned, is_agent, is_out_of_caste, report_count,
  house_name, blood_group, height_cm, weight_kg, taluk, post_office, pincode, family_details, hobbies
) VALUES (
  'de157d2e-a1c8-4f72-b071-562e2ff3bff7', now(), now(), '+919900010053', 'dummy_boy_54@auth.kurichiyar.com', 'ജിനേഷ് ഇല്ലം', 'ജിനേഷ് ഇല്ലം', 28, 'male', '1997-08-03', 'https://noidreeslytswkmsnmcn.supabase.co/storage/v1/object/public/user_documents/profile_photos/placeholder_male.png',
  'ഇടുണി (കിഴക്കുംപാട്ട് - ഇടുണി)', 'കൊടുമ തലക്കര (കെടുംമയിൽ)', 44, 33, 'വയനാട്', 'Kerala',
  'വിദ്യാഭ്യാസമുള്ളതും ലളിതമായ സ്വഭാവമുള്ളതുമായ ഒരു ജീവിതപങ്കാളിയെ ആഗ്രഹിക്കുന്നു. പരസ്പരം മനസ്സിലാക്കി ജീവിക്കാൻ കഴിയണം.', 'ബി.ടെക് എഞ്ചിനീയറിംഗ്', 'കൃഷി', '5 ലക്ഷം രൂപ', 'live', 'APPROVED', 'Approved',
  'adminReview', 'Free', true, true, false, false, false, 0,
  'ഇല്ലം', 'B-', 178, 60, 'മാനന്തവാടി', 'മീനങ്ങാടി', '673844', 'മാതാവും പിതാവും അടങ്ങുന്ന സന്തുഷ്ട കുടുംബം.', '["വായിക്കുക", "കൃഷി ചെയ്യുക", "യാത്ര ചെയ്യുക"]'
);
INSERT INTO public.kurichiyar_profiles (
  id, created_at, updated_at, phone, email, full_name, name, age, gender, dob, photo_url,
  father_tharavadu, mother_tharavadu, father_clan_id, mother_clan_id, district, state,
  about_me, education_level, occupation, income, registration_status, status, approval_status,
  account_status, subscription_tier, is_dummy, photo_approved, is_banned, is_agent, is_out_of_caste, report_count,
  house_name, blood_group, height_cm, weight_kg, taluk, post_office, pincode, family_details, hobbies
) VALUES (
  'bde1992b-1095-406b-918a-12c03cc7a8e9', now(), now(), '+919900010054', 'dummy_boy_55@auth.kurichiyar.com', 'വിജിത്ത് ഓലിക്കൽ', 'വിജിത്ത് ഓലിക്കൽ', 25, 'male', '2001-04-27', 'https://noidreeslytswkmsnmcn.supabase.co/storage/v1/object/public/user_documents/profile_photos/placeholder_male.png',
  'പുച്ചിയേരി (ചായിമ്മൽ)', 'കരിമ്പിച്ചി (കോടങ്ങേല)', 10, 28, 'കോഴിക്കോട്', 'Kerala',
  'സർക്കാർ ജോലി ചെയ്യുന്നു. മാതാപിതാക്കളോടൊപ്പം വയനാട്ടിലാണ് താമസം. കുടുംബസ്നേഹമുള്ള ഒരു പങ്കാളിയെ തേടുന്നു.', 'എം.ബി.എ', 'സ്വകാര്യ കമ്പനി ജോലി', '2 ലക്ഷം രൂപ', 'live', 'APPROVED', 'Approved',
  'adminReview', 'Free', true, true, false, false, false, 0,
  'ഓലിക്കൽ', 'O+', 162, 58, 'വടകര', 'കോടുവള്ളി', '673769', 'മാതാവും പിതാവും അടങ്ങുന്ന സന്തുഷ്ട കുടുംബം.', '["വായിക്കുക", "കൃഷി ചെയ്യുക", "യാത്ര ചെയ്യുക"]'
);
INSERT INTO public.kurichiyar_profiles (
  id, created_at, updated_at, phone, email, full_name, name, age, gender, dob, photo_url,
  father_tharavadu, mother_tharavadu, father_clan_id, mother_clan_id, district, state,
  about_me, education_level, occupation, income, registration_status, status, approval_status,
  account_status, subscription_tier, is_dummy, photo_approved, is_banned, is_agent, is_out_of_caste, report_count,
  house_name, blood_group, height_cm, weight_kg, taluk, post_office, pincode, family_details, hobbies
) VALUES (
  'e9bb5c03-0087-4fa0-8c3d-07aedd0627e5', now(), now(), '+919900010055', 'dummy_boy_56@auth.kurichiyar.com', 'സായൂജ് തെക്കേവീട്', 'സായൂജ് തെക്കേവീട്', 33, 'male', '1993-05-30', 'https://noidreeslytswkmsnmcn.supabase.co/storage/v1/object/public/user_documents/profile_photos/placeholder_male.png',
  'കരിമ്പിലിച്ചി (നെടുമ്പിലാശ്ശേരി)', 'ചമ്മിയേരി (താഴെ തലപ്പുഴ)', 3, 45, 'കണ്ണൂർ', 'Kerala',
  'സർക്കാർ ജോലി ചെയ്യുന്നു. മാതാപിതാക്കളോടൊപ്പം വയനാട്ടിലാണ് താമസം. കുടുംബസ്നേഹമുള്ള ഒരു പങ്കാളിയെ തേടുന്നു.', 'ബി.എസ്.സി. ബിരുദം', 'തയ്യൽ ജോലി', '5 ലക്ഷം രൂപ', 'live', 'APPROVED', 'Approved',
  'adminReview', 'Free', true, true, false, false, false, 0,
  'തെക്കേവീട്', 'A+', 171, 79, 'തലശ്ശേരി', 'പേരാവൂർ', '673739', 'മാതാവും പിതാവും അടങ്ങുന്ന സന്തുഷ്ട കുടുംബം.', '["വായിക്കുക", "കൃഷി ചെയ്യുക", "യാത്ര ചെയ്യുക"]'
);
INSERT INTO public.kurichiyar_profiles (
  id, created_at, updated_at, phone, email, full_name, name, age, gender, dob, photo_url,
  father_tharavadu, mother_tharavadu, father_clan_id, mother_clan_id, district, state,
  about_me, education_level, occupation, income, registration_status, status, approval_status,
  account_status, subscription_tier, is_dummy, photo_approved, is_banned, is_agent, is_out_of_caste, report_count,
  house_name, blood_group, height_cm, weight_kg, taluk, post_office, pincode, family_details, hobbies
) VALUES (
  '32c91873-a455-43d1-982a-199faf061814', now(), now(), '+919900010056', 'dummy_boy_57@auth.kurichiyar.com', 'അഭിനന്ദ് വയലിൽ', 'അഭിനന്ദ് വയലിൽ', 33, 'male', '1992-10-20', 'https://noidreeslytswkmsnmcn.supabase.co/storage/v1/object/public/user_documents/profile_photos/placeholder_male.png',
  'ചാൽപ്പ (പിൽപ്പിടി - പള്ളിയറ)', 'കൊന്നിയോടൻ (കൊന്നിയോട്ട്)', 52, 39, 'വയനാട്', 'Kerala',
  'ബിസിനസ്സ് ചെയ്യുന്നു. മാതാപിതാക്കളെ സ്നേഹത്തോടെ നോക്കുന്ന, നല്ലൊരു സ്വഭാവമുള്ള കുട്ടിയെ വിവാഹം കഴിക്കാൻ താല്പര്യമുണ്ട്.', 'എം.ബി.എ', 'അധ്യാപകൻ', '2 ലക്ഷം രൂപ', 'live', 'APPROVED', 'Approved',
  'adminReview', 'Free', true, true, false, false, false, 0,
  'വയലിൽ', 'B+', 179, 58, 'മാനന്തവാടി', 'കല്പറ്റ', '673567', 'മാതാവും പിതാവും അടങ്ങുന്ന സന്തുഷ്ട കുടുംബം.', '["വായിക്കുക", "കൃഷി ചെയ്യുക", "യാത്ര ചെയ്യുക"]'
);
INSERT INTO public.kurichiyar_profiles (
  id, created_at, updated_at, phone, email, full_name, name, age, gender, dob, photo_url,
  father_tharavadu, mother_tharavadu, father_clan_id, mother_clan_id, district, state,
  about_me, education_level, occupation, income, registration_status, status, approval_status,
  account_status, subscription_tier, is_dummy, photo_approved, is_banned, is_agent, is_out_of_caste, report_count,
  house_name, blood_group, height_cm, weight_kg, taluk, post_office, pincode, family_details, hobbies
) VALUES (
  'e529b89b-54ee-4337-bb48-36446ff9c027', now(), now(), '+919900020000', 'dummy_girl_1@auth.kurichiyar.com', 'രാധ വടക്കേവീട്', 'രാധ വടക്കേവീട്', 23, 'female', '2003-04-28', 'https://noidreeslytswkmsnmcn.supabase.co/storage/v1/object/public/user_documents/profile_photos/placeholder_female.png',
  'പുത്തൂർ (കൊമ്മയാട്)', 'വെണ്ണിയോറ (വെണ്ണിയോറ)', 21, 23, 'കോഴിക്കോട്', 'Kerala',
  'വിദ്യാഭ്യാസമുള്ള, ഉത്തരവാദിത്തബോധമുള്ള ഒരു ജീവിതപങ്കാളിയെ ആഗ്രഹിക്കുന്നു. വയനാട്ടിൽ നിന്നുള്ളവർക്ക് മുൻഗണന.', 'ബി.എസ്.സി. ബിരുദം', 'സ്വകാര്യ കമ്പനി ജോലി', '2 ലക്ഷം രൂപ', 'live', 'APPROVED', 'Approved',
  'adminReview', 'Free', true, true, false, false, false, 0,
  'വടക്കേവീട്', 'O+', 165, 62, 'കൊയിലാണ്ടി', 'കോടുവള്ളി', '673413', 'മാതാവും പിതാവും ഒരു സഹോദരിയും അടങ്ങുന്ന സന്തുഷ്ട കുടുംബം.', '["വായിക്കുക", "തയ്യൽ", "പാചകം"]'
);
INSERT INTO public.kurichiyar_profiles (
  id, created_at, updated_at, phone, email, full_name, name, age, gender, dob, photo_url,
  father_tharavadu, mother_tharavadu, father_clan_id, mother_clan_id, district, state,
  about_me, education_level, occupation, income, registration_status, status, approval_status,
  account_status, subscription_tier, is_dummy, photo_approved, is_banned, is_agent, is_out_of_caste, report_count,
  house_name, blood_group, height_cm, weight_kg, taluk, post_office, pincode, family_details, hobbies
) VALUES (
  '64dd6f70-e0c7-4996-8ef1-41bddbece35a', now(), now(), '+919900020001', 'dummy_girl_2@auth.kurichiyar.com', 'അമ്മിണി മീത്തൽ', 'അമ്മിണി മീത്തൽ', 22, 'female', '2004-03-20', 'https://noidreeslytswkmsnmcn.supabase.co/storage/v1/object/public/user_documents/profile_photos/placeholder_female.png',
  'മങ്ങാനി പുത്തൂർ (മങ്ങാനി)', 'കുന്നംകൊലൻ (ചേരിമ്മൽ)', 22, 13, 'വയനാട്', 'Kerala',
  'ബിരുദം കഴിഞ്ഞു സ്വകാര്യ ജോലി ചെയ്യുന്നു. സമാന ചിന്താഗതിയുള്ള ഒരാളെ പങ്കാളിയായി ലഭിക്കാൻ ആഗ്രഹിക്കുന്നു.', 'പ്ലസ് ടു', 'സ്റ്റാഫ് നഴ്സ്', '3 ലക്ഷം രൂപ', 'live', 'APPROVED', 'Approved',
  'adminReview', 'Free', true, true, false, false, false, 0,
  'മീത്തൽ', 'O+', 152, 48, 'മാനന്തവാടി', 'കല്പറ്റ', '673724', 'മാതാവും പിതാവും ഒരു സഹോദരിയും അടങ്ങുന്ന സന്തുഷ്ട കുടുംബം.', '["വായിക്കുക", "തയ്യൽ", "പാചകം"]'
);
INSERT INTO public.kurichiyar_profiles (
  id, created_at, updated_at, phone, email, full_name, name, age, gender, dob, photo_url,
  father_tharavadu, mother_tharavadu, father_clan_id, mother_clan_id, district, state,
  about_me, education_level, occupation, income, registration_status, status, approval_status,
  account_status, subscription_tier, is_dummy, photo_approved, is_banned, is_agent, is_out_of_caste, report_count,
  house_name, blood_group, height_cm, weight_kg, taluk, post_office, pincode, family_details, hobbies
) VALUES (
  '8e4fe080-e41e-4580-847c-28bf797b0b40', now(), now(), '+919900020002', 'dummy_girl_3@auth.kurichiyar.com', 'കല്യാണി തറവാട്', 'കല്യാണി തറവാട്', 24, 'female', '2001-09-25', 'https://noidreeslytswkmsnmcn.supabase.co/storage/v1/object/public/user_documents/profile_photos/placeholder_female.png',
  'വേമോത്ത് പുച്ചേരി (വയമോത്ത്)', 'പാടിയേരി (ഞാരലോട്ട്)', 25, 41, 'കണ്ണൂർ', 'Kerala',
  'തയ്യൽ ജോലി ചെയ്യുന്നു. ലളിതമായ സ്വഭാവമുള്ള, നല്ലൊരു ജോലി ഉള്ള ഒരാളെ വിവാഹത്തിന് ആഗ്രഹിക്കുന്നു.', 'ജനറൽ നഴ്സിംഗ്', 'അധ്യാപകൻ', '3 ലക്ഷം രൂപ', 'live', 'APPROVED', 'Approved',
  'adminReview', 'Free', true, true, false, false, false, 0,
  'തറവാട്', 'A-', 158, 54, 'തലശ്ശേരി', 'പേരാവൂർ', '673308', 'മാതാവും പിതാവും ഒരു സഹോദരിയും അടങ്ങുന്ന സന്തുഷ്ട കുടുംബം.', '["വായിക്കുക", "തയ്യൽ", "പാചകം"]'
);
INSERT INTO public.kurichiyar_profiles (
  id, created_at, updated_at, phone, email, full_name, name, age, gender, dob, photo_url,
  father_tharavadu, mother_tharavadu, father_clan_id, mother_clan_id, district, state,
  about_me, education_level, occupation, income, registration_status, status, approval_status,
  account_status, subscription_tier, is_dummy, photo_approved, is_banned, is_agent, is_out_of_caste, report_count,
  house_name, blood_group, height_cm, weight_kg, taluk, post_office, pincode, family_details, hobbies
) VALUES (
  'ed310172-f1cd-4ab5-aa99-bd5d1581aec3', now(), now(), '+919900020003', 'dummy_girl_4@auth.kurichiyar.com', 'ലക്ഷ്മി മണൽവയൽ', 'ലക്ഷ്മി മണൽവയൽ', 31, 'female', '1994-12-15', 'https://noidreeslytswkmsnmcn.supabase.co/storage/v1/object/public/user_documents/profile_photos/placeholder_female.png',
  'കൊന്നിയോടൻ (കൊന്നിയോട്ട്)', 'ചെറുമ്പാലൻ (കാക്കൻ ചിറ)', 39, 24, 'വയനാട്', 'Kerala',
  'ബിരുദം കഴിഞ്ഞു സ്വകാര്യ ജോലി ചെയ്യുന്നു. സമാന ചിന്താഗതിയുള്ള ഒരാളെ പങ്കാളിയായി ലഭിക്കാൻ ആഗ്രഹിക്കുന്നു.', 'പ്ലസ് ടു', 'കൃഷി', '3 ലക്ഷം രൂപ', 'live', 'APPROVED', 'Approved',
  'adminReview', 'Free', true, true, false, false, false, 0,
  'മണൽവയൽ', 'O+', 154, 62, 'മാനന്തവാടി', 'കല്പറ്റ', '673164', 'മാതാവും പിതാവും ഒരു സഹോദരിയും അടങ്ങുന്ന സന്തുഷ്ട കുടുംബം.', '["വായിക്കുക", "തയ്യൽ", "പാചകം"]'
);
INSERT INTO public.kurichiyar_profiles (
  id, created_at, updated_at, phone, email, full_name, name, age, gender, dob, photo_url,
  father_tharavadu, mother_tharavadu, father_clan_id, mother_clan_id, district, state,
  about_me, education_level, occupation, income, registration_status, status, approval_status,
  account_status, subscription_tier, is_dummy, photo_approved, is_banned, is_agent, is_out_of_caste, report_count,
  house_name, blood_group, height_cm, weight_kg, taluk, post_office, pincode, family_details, hobbies
) VALUES (
  '58bd47ff-b05c-484a-a854-8804b7361d4f', now(), now(), '+919900020004', 'dummy_girl_5@auth.kurichiyar.com', 'പാർവ്വതി എടക്കുടി', 'പാർവ്വതി എടക്കുടി', 21, 'female', '2005-01-10', 'https://noidreeslytswkmsnmcn.supabase.co/storage/v1/object/public/user_documents/profile_photos/placeholder_female.png',
  'എരിശേരി (ചേരള)', 'മൂത്തേടൻ (മൂത്തേടത്ത്)', 50, 27, 'വയനാട്', 'Kerala',
  'ബിരുദം കഴിഞ്ഞു സ്വകാര്യ ജോലി ചെയ്യുന്നു. സമാന ചിന്താഗതിയുള്ള ഒരാളെ പങ്കാളിയായി ലഭിക്കാൻ ആഗ്രഹിക്കുന്നു.', 'ബി.കോം ബിരുദം', 'സർക്കാർ ജീവനക്കാരൻ', '4 ലക്ഷം രൂപ', 'live', 'APPROVED', 'Approved',
  'adminReview', 'Free', true, true, false, false, false, 0,
  'എടക്കുടി', 'B-', 165, 63, 'വൈത്തിരി', 'മീനങ്ങാടി', '673374', 'മാതാവും പിതാവും ഒരു സഹോദരിയും അടങ്ങുന്ന സന്തുഷ്ട കുടുംബം.', '["വായിക്കുക", "തയ്യൽ", "പാചകം"]'
);
INSERT INTO public.kurichiyar_profiles (
  id, created_at, updated_at, phone, email, full_name, name, age, gender, dob, photo_url,
  father_tharavadu, mother_tharavadu, father_clan_id, mother_clan_id, district, state,
  about_me, education_level, occupation, income, registration_status, status, approval_status,
  account_status, subscription_tier, is_dummy, photo_approved, is_banned, is_agent, is_out_of_caste, report_count,
  house_name, blood_group, height_cm, weight_kg, taluk, post_office, pincode, family_details, hobbies
) VALUES (
  '468fcbb2-f414-4b46-80d1-e2755a977e1c', now(), now(), '+919900020005', 'dummy_girl_6@auth.kurichiyar.com', 'ദേവിക തറവാട്', 'ദേവിക തറവാട്', 24, 'female', '2002-06-02', 'https://noidreeslytswkmsnmcn.supabase.co/storage/v1/object/public/user_documents/profile_photos/placeholder_female.png',
  'കൊന്നിയോടൻ (കൊന്നിയോട്ട്)', 'പെരലാഞ്ചി (മുതുവട്ടിൽ)', 39, 42, 'വയനാട്', 'Kerala',
  'തയ്യൽ ജോലി ചെയ്യുന്നു. ലളിതമായ സ്വഭാവമുള്ള, നല്ലൊരു ജോലി ഉള്ള ഒരാളെ വിവാഹത്തിന് ആഗ്രഹിക്കുന്നു.', 'ബി.എസ്.സി. ബിരുദം', 'കൃഷി', '1 ലക്ഷം രൂപ', 'live', 'APPROVED', 'Approved',
  'adminReview', 'Free', true, true, false, false, false, 0,
  'തറവാട്', 'A-', 163, 65, 'മാനന്തവാടി', 'മീനങ്ങാടി', '673757', 'മാതാവും പിതാവും ഒരു സഹോദരിയും അടങ്ങുന്ന സന്തുഷ്ട കുടുംബം.', '["വായിക്കുക", "തയ്യൽ", "പാചകം"]'
);
INSERT INTO public.kurichiyar_profiles (
  id, created_at, updated_at, phone, email, full_name, name, age, gender, dob, photo_url,
  father_tharavadu, mother_tharavadu, father_clan_id, mother_clan_id, district, state,
  about_me, education_level, occupation, income, registration_status, status, approval_status,
  account_status, subscription_tier, is_dummy, photo_approved, is_banned, is_agent, is_out_of_caste, report_count,
  house_name, blood_group, height_cm, weight_kg, taluk, post_office, pincode, family_details, hobbies
) VALUES (
  'd42e979a-fbf4-4da5-b625-b05b3e0f2da5', now(), now(), '+919900020006', 'dummy_girl_7@auth.kurichiyar.com', 'അഞ്ജന വടക്കേവീട്', 'അഞ്ജന വടക്കേവീട്', 22, 'female', '2003-08-31', 'https://noidreeslytswkmsnmcn.supabase.co/storage/v1/object/public/user_documents/profile_photos/placeholder_female.png',
  'വെള്ളരി മിലിയാടി (വെള്ളരി)', 'എടമന (എടമന)', 36, 43, 'കണ്ണൂർ', 'Kerala',
  'വിദ്യാഭ്യാസമുള്ള, ഉത്തരവാദിത്തബോധമുള്ള ഒരു ജീവിതപങ്കാളിയെ ആഗ്രഹിക്കുന്നു. വയനാട്ടിൽ നിന്നുള്ളവർക്ക് മുൻഗണന.', 'എം.എ. ബിരുദം', 'софтവെയർ എഞ്ചിനീയർ', '2 ലക്ഷം രൂപ', 'live', 'APPROVED', 'Approved',
  'adminReview', 'Free', true, true, false, false, false, 0,
  'വടക്കേവീട്', 'AB+', 153, 60, 'ഇരിട്ടി', 'മട്ടന്നൂർ', '673977', 'മാതാവും പിതാവും ഒരു സഹോദരിയും അടങ്ങുന്ന സന്തുഷ്ട കുടുംബം.', '["വായിക്കുക", "തയ്യൽ", "പാചകം"]'
);
INSERT INTO public.kurichiyar_profiles (
  id, created_at, updated_at, phone, email, full_name, name, age, gender, dob, photo_url,
  father_tharavadu, mother_tharavadu, father_clan_id, mother_clan_id, district, state,
  about_me, education_level, occupation, income, registration_status, status, approval_status,
  account_status, subscription_tier, is_dummy, photo_approved, is_banned, is_agent, is_out_of_caste, report_count,
  house_name, blood_group, height_cm, weight_kg, taluk, post_office, pincode, family_details, hobbies
) VALUES (
  '7857ca13-6dfc-4204-80e4-a22a87f6b83b', now(), now(), '+919900020007', 'dummy_girl_8@auth.kurichiyar.com', 'ആതിര മീത്തൽ', 'ആതിര മീത്തൽ', 22, 'female', '2004-01-07', 'https://noidreeslytswkmsnmcn.supabase.co/storage/v1/object/public/user_documents/profile_photos/placeholder_female.png',
  'കാവ് പാലോടൻ (കാവില്)', 'മൂത്തേടൻ (മൂത്തേടത്ത്)', 17, 27, 'കണ്ണൂർ', 'Kerala',
  'മാതാപിതാക്കളെയും കുടുംബത്തെയും ഒരുപോലെ സ്നേഹിക്കുന്ന ഒരു പങ്കാളിയെ തേടുന്നു. പരസ്പര ബഹുമാനമുള്ള ജീവിതം നയിക്കാൻ താല്പര്യം.', 'പ്ലസ് ടു', 'കൃഷി', '3 ലക്ഷം രൂപ', 'live', 'APPROVED', 'Approved',
  'adminReview', 'Free', true, true, false, false, false, 0,
  'മീത്തൽ', 'AB+', 159, 52, 'തലശ്ശേരി', 'കേളകം', '673171', 'മാതാവും പിതാവും ഒരു സഹോദരിയും അടങ്ങുന്ന സന്തുഷ്ട കുടുംബം.', '["വായിക്കുക", "തയ്യൽ", "പാചകം"]'
);
INSERT INTO public.kurichiyar_profiles (
  id, created_at, updated_at, phone, email, full_name, name, age, gender, dob, photo_url,
  father_tharavadu, mother_tharavadu, father_clan_id, mother_clan_id, district, state,
  about_me, education_level, occupation, income, registration_status, status, approval_status,
  account_status, subscription_tier, is_dummy, photo_approved, is_banned, is_agent, is_out_of_caste, report_count,
  house_name, blood_group, height_cm, weight_kg, taluk, post_office, pincode, family_details, hobbies
) VALUES (
  'b45928d8-e863-4c47-a94b-cbb4f90c03b6', now(), now(), '+919900020008', 'dummy_girl_9@auth.kurichiyar.com', 'രമ്യ പുത്തൻവീട്', 'രമ്യ പുത്തൻവീട്', 30, 'female', '1995-08-15', 'https://noidreeslytswkmsnmcn.supabase.co/storage/v1/object/public/user_documents/profile_photos/placeholder_female.png',
  'കരിമ്പിച്ചി (കോടങ്ങേല)', 'ചേരക്കര (കോലിമൂല)', 28, 8, 'വയനാട്', 'Kerala',
  'ബിരുദം കഴിഞ്ഞു സ്വകാര്യ ജോലി ചെയ്യുന്നു. സമാന ചിന്താഗതിയുള്ള ഒരാളെ പങ്കാളിയായി ലഭിക്കാൻ ആഗ്രഹിക്കുന്നു.', 'എസ്.എസ്.എൽ.സി', 'സ്റ്റാഫ് നഴ്സ്', '1 ലക്ഷം രൂപ', 'live', 'APPROVED', 'Approved',
  'adminReview', 'Free', true, true, false, false, false, 0,
  'പുത്തൻവീട്', 'B+', 150, 55, 'മാനന്തവാടി', 'മീനങ്ങാടി', '673231', 'മാതാവും പിതാവും ഒരു സഹോദരിയും അടങ്ങുന്ന സന്തുഷ്ട കുടുംബം.', '["വായിക്കുക", "തയ്യൽ", "പാചകം"]'
);
INSERT INTO public.kurichiyar_profiles (
  id, created_at, updated_at, phone, email, full_name, name, age, gender, dob, photo_url,
  father_tharavadu, mother_tharavadu, father_clan_id, mother_clan_id, district, state,
  about_me, education_level, occupation, income, registration_status, status, approval_status,
  account_status, subscription_tier, is_dummy, photo_approved, is_banned, is_agent, is_out_of_caste, report_count,
  house_name, blood_group, height_cm, weight_kg, taluk, post_office, pincode, family_details, hobbies
) VALUES (
  '752359a2-657a-4fda-95f0-36ecebf5a479', now(), now(), '+919900020009', 'dummy_girl_10@auth.kurichiyar.com', 'കാവ്യ കുന്നിൻമേൽ', 'കാവ്യ കുന്നിൻമേൽ', 28, 'female', '1998-07-23', 'https://noidreeslytswkmsnmcn.supabase.co/storage/v1/object/public/user_documents/profile_photos/placeholder_female.png',
  'വളാടൻ (ഇല്ലത്തുമൂല)', 'ചമ്മിയേരി (താഴെ തലപ്പുഴ)', 5, 45, 'കോഴിക്കോട്', 'Kerala',
  'മാതാപിതാക്കളെയും കുടുംബത്തെയും ഒരുപോലെ സ്നേഹിക്കുന്ന ഒരു പങ്കാളിയെ തേടുന്നു. പരസ്പര ബഹുമാനമുള്ള ജീവിതം നയിക്കാൻ താല്പര്യം.', 'ബി.കോം ബിരുദം', 'തയ്യൽ ജോലി', '3 ലക്ഷം രൂപ', 'live', 'APPROVED', 'Approved',
  'adminReview', 'Free', true, true, false, false, false, 0,
  'കുന്നിൻമേൽ', 'O+', 151, 48, 'കൊയിലാണ്ടി', 'പേരാമ്പ്ര', '673835', 'മാതാവും പിതാവും ഒരു സഹോദരിയും അടങ്ങുന്ന സന്തുഷ്ട കുടുംബം.', '["വായിക്കുക", "തയ്യൽ", "പാചകം"]'
);
INSERT INTO public.kurichiyar_profiles (
  id, created_at, updated_at, phone, email, full_name, name, age, gender, dob, photo_url,
  father_tharavadu, mother_tharavadu, father_clan_id, mother_clan_id, district, state,
  about_me, education_level, occupation, income, registration_status, status, approval_status,
  account_status, subscription_tier, is_dummy, photo_approved, is_banned, is_agent, is_out_of_caste, report_count,
  house_name, blood_group, height_cm, weight_kg, taluk, post_office, pincode, family_details, hobbies
) VALUES (
  '530a18b4-b0f5-4355-9b26-41a4bd8da96d', now(), now(), '+919900020010', 'dummy_girl_11@auth.kurichiyar.com', 'സരിത കിഴക്കേവീട്', 'സരിത കിഴക്കേവീട്', 27, 'female', '1998-10-27', 'https://noidreeslytswkmsnmcn.supabase.co/storage/v1/object/public/user_documents/profile_photos/placeholder_female.png',
  'ചമ്മിയേരി (താഴെ തലപ്പുഴ)', 'പടനി (കുഴികണ്ടം)', 45, 53, 'കണ്ണൂർ', 'Kerala',
  'തയ്യൽ ജോലി ചെയ്യുന്നു. ലളിതമായ സ്വഭാവമുള്ള, നല്ലൊരു ജോലി ഉള്ള ഒരാളെ വിവാഹത്തിന് ആഗ്രഹിക്കുന്നു.', 'ജനറൽ നഴ്സിംഗ്', 'തയ്യൽ ജോലി', '4 ലക്ഷം രൂപ', 'live', 'APPROVED', 'Approved',
  'adminReview', 'Free', true, true, false, false, false, 0,
  'കിഴക്കേവീട്', 'O+', 162, 50, 'ഇരിട്ടി', 'മട്ടന്നൂർ', '673539', 'മാതാവും പിതാവും ഒരു സഹോദരിയും അടങ്ങുന്ന സന്തുഷ്ട കുടുംബം.', '["വായിക്കുക", "തയ്യൽ", "പാചകം"]'
);
INSERT INTO public.kurichiyar_profiles (
  id, created_at, updated_at, phone, email, full_name, name, age, gender, dob, photo_url,
  father_tharavadu, mother_tharavadu, father_clan_id, mother_clan_id, district, state,
  about_me, education_level, occupation, income, registration_status, status, approval_status,
  account_status, subscription_tier, is_dummy, photo_approved, is_banned, is_agent, is_out_of_caste, report_count,
  house_name, blood_group, height_cm, weight_kg, taluk, post_office, pincode, family_details, hobbies
) VALUES (
  '95fa5d88-dd76-4828-a384-e1bb3ec3f048', now(), now(), '+919900020011', 'dummy_girl_12@auth.kurichiyar.com', 'സുനിത ചാലിൽ', 'സുനിത ചാലിൽ', 25, 'female', '2001-03-30', 'https://noidreeslytswkmsnmcn.supabase.co/storage/v1/object/public/user_documents/profile_photos/placeholder_female.png',
  'അയിനിയാടൻ (ചെന്നംപാടി)', 'വെണ്ണിയോറ (വെണ്ണിയോറ)', 51, 23, 'വയനാട്', 'Kerala',
  'വിദ്യാഭ്യാസമുള്ള, ഉത്തരവാദിത്തബോധമുള്ള ഒരു ജീവിതപങ്കാളിയെ ആഗ്രഹിക്കുന്നു. വയനാട്ടിൽ നിന്നുള്ളവർക്ക് മുൻഗണന.', 'എം.എ. ബിരുദം', 'അധ്യാപകൻ', '3 ലക്ഷം രൂപ', 'live', 'APPROVED', 'Approved',
  'adminReview', 'Free', true, true, false, false, false, 0,
  'ചാലിൽ', 'AB+', 167, 58, 'വൈത്തിരി', 'കല്പറ്റ', '673510', 'മാതാവും പിതാവും ഒരു സഹോദരിയും അടങ്ങുന്ന സന്തുഷ്ട കുടുംബം.', '["വായിക്കുക", "തയ്യൽ", "പാചകം"]'
);
INSERT INTO public.kurichiyar_profiles (
  id, created_at, updated_at, phone, email, full_name, name, age, gender, dob, photo_url,
  father_tharavadu, mother_tharavadu, father_clan_id, mother_clan_id, district, state,
  about_me, education_level, occupation, income, registration_status, status, approval_status,
  account_status, subscription_tier, is_dummy, photo_approved, is_banned, is_agent, is_out_of_caste, report_count,
  house_name, blood_group, height_cm, weight_kg, taluk, post_office, pincode, family_details, hobbies
) VALUES (
  '2374d0eb-3db6-4cda-8b1a-7b1b22b839b5', now(), now(), '+919900020012', 'dummy_girl_13@auth.kurichiyar.com', 'ബിന്ദു എടക്കുടി', 'ബിന്ദു എടക്കുടി', 30, 'female', '1995-11-26', 'https://noidreeslytswkmsnmcn.supabase.co/storage/v1/object/public/user_documents/profile_photos/placeholder_female.png',
  'കുണ്ടര (കുണ്ടര മൂല)', 'തെറ്റ (വേങ്ങലോട്ട്)', 11, 40, 'വയനാട്', 'Kerala',
  'വിദ്യാഭ്യാസമുള്ള, ഉത്തരവാദിത്തബോധമുള്ള ഒരു ജീവിതപങ്കാളിയെ ആഗ്രഹിക്കുന്നു. വയനാട്ടിൽ നിന്നുള്ളവർക്ക് മുൻഗണന.', 'ബി.ടെക് എഞ്ചിനീയറിംഗ്', 'സർക്കാർ ജീവനക്കാരൻ', '3 ലക്ഷം രൂപ', 'live', 'APPROVED', 'Approved',
  'adminReview', 'Free', true, true, false, false, false, 0,
  'എടക്കുടി', 'A+', 156, 61, 'സുൽത്താൻ ബത്തേരി', 'കല്പറ്റ', '673462', 'മാതാവും പിതാവും ഒരു സഹോദരിയും അടങ്ങുന്ന സന്തുഷ്ട കുടുംബം.', '["വായിക്കുക", "തയ്യൽ", "പാചകം"]'
);
INSERT INTO public.kurichiyar_profiles (
  id, created_at, updated_at, phone, email, full_name, name, age, gender, dob, photo_url,
  father_tharavadu, mother_tharavadu, father_clan_id, mother_clan_id, district, state,
  about_me, education_level, occupation, income, registration_status, status, approval_status,
  account_status, subscription_tier, is_dummy, photo_approved, is_banned, is_agent, is_out_of_caste, report_count,
  house_name, blood_group, height_cm, weight_kg, taluk, post_office, pincode, family_details, hobbies
) VALUES (
  'bee7589d-d3c2-4e5b-ab53-9f49c230b822', now(), now(), '+919900020013', 'dummy_girl_14@auth.kurichiyar.com', 'സിന്ധു ഓലിക്കൽ', 'സിന്ധു ഓലിക്കൽ', 26, 'female', '2000-03-15', 'https://noidreeslytswkmsnmcn.supabase.co/storage/v1/object/public/user_documents/profile_photos/placeholder_female.png',
  'ഒതയോം കൊലൻ (ഒതയോത്ത്)', 'ചെറുമ്പാലൻ (കാക്കൻ ചിറ)', 14, 24, 'കോഴിക്കോട്', 'Kerala',
  'മാതാപിതാക്കളെയും കുടുംബത്തെയും ഒരുപോലെ സ്നേഹിക്കുന്ന ഒരു പങ്കാളിയെ തേടുന്നു. പരസ്പര ബഹുമാനമുള്ള ജീവിതം നയിക്കാൻ താല്പര്യം.', 'എം.ബി.എ', 'സ്റ്റാഫ് നഴ്സ്', '4 ലക്ഷം രൂപ', 'live', 'APPROVED', 'Approved',
  'adminReview', 'Free', true, true, false, false, false, 0,
  'ഓലിക്കൽ', 'A-', 166, 65, 'കൊയിലാണ്ടി', 'കോടുവള്ളി', '673195', 'മാതാവും പിതാവും ഒരു സഹോദരിയും അടങ്ങുന്ന സന്തുഷ്ട കുടുംബം.', '["വായിക്കുക", "തയ്യൽ", "പാചകം"]'
);
INSERT INTO public.kurichiyar_profiles (
  id, created_at, updated_at, phone, email, full_name, name, age, gender, dob, photo_url,
  father_tharavadu, mother_tharavadu, father_clan_id, mother_clan_id, district, state,
  about_me, education_level, occupation, income, registration_status, status, approval_status,
  account_status, subscription_tier, is_dummy, photo_approved, is_banned, is_agent, is_out_of_caste, report_count,
  house_name, blood_group, height_cm, weight_kg, taluk, post_office, pincode, family_details, hobbies
) VALUES (
  '3b283d73-9bc7-4798-a8eb-2e547cb09c10', now(), now(), '+919900020014', 'dummy_girl_15@auth.kurichiyar.com', 'മിനി മണൽവയൽ', 'മിനി മണൽവയൽ', 20, 'female', '2005-08-19', 'https://noidreeslytswkmsnmcn.supabase.co/storage/v1/object/public/user_documents/profile_photos/placeholder_female.png',
  'അയിനിയാടൻ (ചെന്നംപാടി)', 'കല്ലിയോടൻ (കല്ലിയോട്ട്)', 51, 9, 'വയനാട്', 'Kerala',
  'തയ്യൽ ജോലി ചെയ്യുന്നു. ലളിതമായ സ്വഭാവമുള്ള, നല്ലൊരു ജോലി ഉള്ള ഒരാളെ വിവാഹത്തിന് ആഗ്രഹിക്കുന്നു.', 'എം.എസ്.സി. ബിരുദം', 'കൃഷി', '1 ലക്ഷം രൂപ', 'live', 'APPROVED', 'Approved',
  'adminReview', 'Free', true, true, false, false, false, 0,
  'മണൽവയൽ', 'AB+', 163, 63, 'വൈത്തിരി', 'കല്പറ്റ', '673574', 'മാതാവും പിതാവും ഒരു സഹോദരിയും അടങ്ങുന്ന സന്തുഷ്ട കുടുംബം.', '["വായിക്കുക", "തയ്യൽ", "പാചകം"]'
);
INSERT INTO public.kurichiyar_profiles (
  id, created_at, updated_at, phone, email, full_name, name, age, gender, dob, photo_url,
  father_tharavadu, mother_tharavadu, father_clan_id, mother_clan_id, district, state,
  about_me, education_level, occupation, income, registration_status, status, approval_status,
  account_status, subscription_tier, is_dummy, photo_approved, is_banned, is_agent, is_out_of_caste, report_count,
  house_name, blood_group, height_cm, weight_kg, taluk, post_office, pincode, family_details, hobbies
) VALUES (
  '0509c136-d9b2-4860-9ac1-68d0bc5ed62c', now(), now(), '+919900020015', 'dummy_girl_16@auth.kurichiyar.com', 'ഷീല പടിഞ്ഞാറേവീട്', 'ഷീല പടിഞ്ഞാറേവീട്', 27, 'female', '1999-06-28', 'https://noidreeslytswkmsnmcn.supabase.co/storage/v1/object/public/user_documents/profile_photos/placeholder_female.png',
  'ചെരൂല് (മേനരത്ത്)', 'ഒതയോം കൊലൻ (ഒതയോത്ത്)', 49, 14, 'കോഴിക്കോട്', 'Kerala',
  'വിദ്യാഭ്യാസമുള്ള, ഉത്തരവാദിത്തബോധമുള്ള ഒരു ജീവിതപങ്കാളിയെ ആഗ്രഹിക്കുന്നു. വയനാട്ടിൽ നിന്നുള്ളവർക്ക് മുൻഗണന.', 'ജനറൽ നഴ്സിംഗ്', 'ഡ്രൈവർ', '1 ലക്ഷം രൂപ', 'live', 'APPROVED', 'Approved',
  'adminReview', 'Free', true, true, false, false, false, 0,
  'പടിഞ്ഞാറേവീട്', 'A+', 153, 54, 'താമരശ്ശേരി', 'പേരാമ്പ്ര', '673367', 'മാതാവും പിതാവും ഒരു സഹോദരിയും അടങ്ങുന്ന സന്തുഷ്ട കുടുംബം.', '["വായിക്കുക", "തയ്യൽ", "പാചകം"]'
);
INSERT INTO public.kurichiyar_profiles (
  id, created_at, updated_at, phone, email, full_name, name, age, gender, dob, photo_url,
  father_tharavadu, mother_tharavadu, father_clan_id, mother_clan_id, district, state,
  about_me, education_level, occupation, income, registration_status, status, approval_status,
  account_status, subscription_tier, is_dummy, photo_approved, is_banned, is_agent, is_out_of_caste, report_count,
  house_name, blood_group, height_cm, weight_kg, taluk, post_office, pincode, family_details, hobbies
) VALUES (
  '87596c56-2865-4c83-a4c7-805c567fee49', now(), now(), '+919900020016', 'dummy_girl_17@auth.kurichiyar.com', 'ഗീത വലിപ്പവീട്', 'ഗീത വലിപ്പവീട്', 26, 'female', '1999-11-26', 'https://noidreeslytswkmsnmcn.supabase.co/storage/v1/object/public/user_documents/profile_photos/placeholder_female.png',
  'കാക്കിലി (ഓടുടുമ്പിൽ)', 'പരക്കടൻ (വെള്ളോട്ട്)', 47, 48, 'വയനാട്', 'Kerala',
  'ബിരുദം കഴിഞ്ഞു സ്വകാര്യ ജോലി ചെയ്യുന്നു. സമാന ചിന്താഗതിയുള്ള ഒരാളെ പങ്കാളിയായി ലഭിക്കാൻ ആഗ്രഹിക്കുന്നു.', 'ബി.കോം ബിരുദം', 'തയ്യൽ ജോലി', '3 ലക്ഷം രൂപ', 'live', 'APPROVED', 'Approved',
  'adminReview', 'Free', true, true, false, false, false, 0,
  'വലിപ്പവീട്', 'O+', 157, 56, 'മാനന്തവാടി', 'അമ്പലക്കുന്ന്', '673143', 'മാതാവും പിതാവും ഒരു സഹോദരിയും അടങ്ങുന്ന സന്തുഷ്ട കുടുംബം.', '["വായിക്കുക", "തയ്യൽ", "പാചകം"]'
);
INSERT INTO public.kurichiyar_profiles (
  id, created_at, updated_at, phone, email, full_name, name, age, gender, dob, photo_url,
  father_tharavadu, mother_tharavadu, father_clan_id, mother_clan_id, district, state,
  about_me, education_level, occupation, income, registration_status, status, approval_status,
  account_status, subscription_tier, is_dummy, photo_approved, is_banned, is_agent, is_out_of_caste, report_count,
  house_name, blood_group, height_cm, weight_kg, taluk, post_office, pincode, family_details, hobbies
) VALUES (
  '4563119b-6107-4d79-a603-4b10797176d7', now(), now(), '+919900020017', 'dummy_girl_18@auth.kurichiyar.com', 'സൗമ്യ പുത്തൻവീട്', 'സൗമ്യ പുത്തൻവീട്', 26, 'female', '2000-03-03', 'https://noidreeslytswkmsnmcn.supabase.co/storage/v1/object/public/user_documents/profile_photos/placeholder_female.png',
  'ചെന്നലര കുറ്റിയോടൻ (ചെന്നലര)', 'ചേലപ്പേരോൻ (ഈരനകൊല്ലി)', 18, 57, 'കണ്ണൂർ', 'Kerala',
  'തയ്യൽ ജോലി ചെയ്യുന്നു. ലളിതമായ സ്വഭാവമുള്ള, നല്ലൊരു ജോലി ഉള്ള ഒരാളെ വിവാഹത്തിന് ആഗ്രഹിക്കുന്നു.', 'ജനറൽ നഴ്സിംഗ്', 'തയ്യൽ ജോലി', '1 ലക്ഷം രൂപ', 'live', 'APPROVED', 'Approved',
  'adminReview', 'Free', true, true, false, false, false, 0,
  'പുത്തൻവീട്', 'AB+', 159, 54, 'ഇരിട്ടി', 'മട്ടന്നൂർ', '673538', 'മാതാവും പിതാവും ഒരു സഹോദരിയും അടങ്ങുന്ന സന്തുഷ്ട കുടുംബം.', '["വായിക്കുക", "തയ്യൽ", "പാചകം"]'
);
INSERT INTO public.kurichiyar_profiles (
  id, created_at, updated_at, phone, email, full_name, name, age, gender, dob, photo_url,
  father_tharavadu, mother_tharavadu, father_clan_id, mother_clan_id, district, state,
  about_me, education_level, occupation, income, registration_status, status, approval_status,
  account_status, subscription_tier, is_dummy, photo_approved, is_banned, is_agent, is_out_of_caste, report_count,
  house_name, blood_group, height_cm, weight_kg, taluk, post_office, pincode, family_details, hobbies
) VALUES (
  'a377297a-61eb-4b21-befd-929271047b7c', now(), now(), '+919900020018', 'dummy_girl_19@auth.kurichiyar.com', 'ധന്യ കുന്നിൻമേൽ', 'ധന്യ കുന്നിൻമേൽ', 23, 'female', '2002-10-03', 'https://noidreeslytswkmsnmcn.supabase.co/storage/v1/object/public/user_documents/profile_photos/placeholder_female.png',
  'പെരലാഞ്ചി (മുതുവട്ടിൽ)', 'എടപ്പിടി (എടപ്പിടി)', 42, 15, 'വയനാട്', 'Kerala',
  'ബിരുദം കഴിഞ്ഞു സ്വകാര്യ ജോലി ചെയ്യുന്നു. സമാന ചിന്താഗതിയുള്ള ഒരാളെ പങ്കാളിയായി ലഭിക്കാൻ ആഗ്രഹിക്കുന്നു.', 'ബി.എ. ബിരുദം', 'സ്വകാര്യ കമ്പനി ജോലി', '1 ലക്ഷം രൂപ', 'live', 'APPROVED', 'Approved',
  'adminReview', 'Free', true, true, false, false, false, 0,
  'കുന്നിൻമേൽ', 'A-', 158, 55, 'മാനന്തവാടി', 'കല്പറ്റ', '673869', 'മാതാവും പിതാവും ഒരു സഹോദരിയും അടങ്ങുന്ന സന്തുഷ്ട കുടുംബം.', '["വായിക്കുക", "തയ്യൽ", "പാചകം"]'
);
INSERT INTO public.kurichiyar_profiles (
  id, created_at, updated_at, phone, email, full_name, name, age, gender, dob, photo_url,
  father_tharavadu, mother_tharavadu, father_clan_id, mother_clan_id, district, state,
  about_me, education_level, occupation, income, registration_status, status, approval_status,
  account_status, subscription_tier, is_dummy, photo_approved, is_banned, is_agent, is_out_of_caste, report_count,
  house_name, blood_group, height_cm, weight_kg, taluk, post_office, pincode, family_details, hobbies
) VALUES (
  '3d930cd2-cd35-4bc6-8526-0b75ad7ad0a9', now(), now(), '+919900020019', 'dummy_girl_20@auth.kurichiyar.com', 'രശ്മി എടക്കുടി', 'രശ്മി എടക്കുടി', 30, 'female', '1996-07-16', 'https://noidreeslytswkmsnmcn.supabase.co/storage/v1/object/public/user_documents/profile_photos/placeholder_female.png',
  'എരിശേരി (ചേരള)', 'പെരലാഞ്ചി (മുതുവട്ടിൽ)', 50, 42, 'കോഴിക്കോട്', 'Kerala',
  'തയ്യൽ ജോലി ചെയ്യുന്നു. ലളിതമായ സ്വഭാവമുള്ള, നല്ലൊരു ജോലി ഉള്ള ഒരാളെ വിവാഹത്തിന് ആഗ്രഹിക്കുന്നു.', 'എം.എസ്.സി. ബിരുദം', 'സ്വകാര്യ കമ്പനി ജോലി', '1 ലക്ഷം രൂപ', 'live', 'APPROVED', 'Approved',
  'adminReview', 'Free', true, true, false, false, false, 0,
  'എടക്കുടി', 'A+', 151, 55, 'കൊയിലാണ്ടി', 'പേരാമ്പ്ര', '673469', 'മാതാവും പിതാവും ഒരു സഹോദരിയും അടങ്ങുന്ന സന്തുഷ്ട കുടുംബം.', '["വായിക്കുക", "തയ്യൽ", "പാചകം"]'
);
INSERT INTO public.kurichiyar_profiles (
  id, created_at, updated_at, phone, email, full_name, name, age, gender, dob, photo_url,
  father_tharavadu, mother_tharavadu, father_clan_id, mother_clan_id, district, state,
  about_me, education_level, occupation, income, registration_status, status, approval_status,
  account_status, subscription_tier, is_dummy, photo_approved, is_banned, is_agent, is_out_of_caste, report_count,
  house_name, blood_group, height_cm, weight_kg, taluk, post_office, pincode, family_details, hobbies
) VALUES (
  '7fb223c1-3290-4f80-ad1a-8baacc144388', now(), now(), '+919900020020', 'dummy_girl_21@auth.kurichiyar.com', 'ദിവ്യ എടക്കുടി', 'ദിവ്യ എടക്കുടി', 26, 'female', '2000-06-18', 'https://noidreeslytswkmsnmcn.supabase.co/storage/v1/object/public/user_documents/profile_photos/placeholder_female.png',
  'ചേരക്കര (കോലിമൂല)', 'കല്ലിയോടൻ (കല്ലിയോട്ട്)', 8, 9, 'കോഴിക്കോട്', 'Kerala',
  'വിദ്യാഭ്യാസമുള്ള, ഉത്തരവാദിത്തബോധമുള്ള ഒരു ജീവിതപങ്കാളിയെ ആഗ്രഹിക്കുന്നു. വയനാട്ടിൽ നിന്നുള്ളവർക്ക് മുൻഗണന.', 'എസ്.എസ്.എൽ.സി', 'തയ്യൽ ജോലി', '3 ലക്ഷം രൂപ', 'live', 'APPROVED', 'Approved',
  'adminReview', 'Free', true, true, false, false, false, 0,
  'എടക്കുടി', 'O+', 162, 49, 'കൊയിലാണ്ടി', 'കോടുവള്ളി', '673785', 'മാതാവും പിതാവും ഒരു സഹോദരിയും അടങ്ങുന്ന സന്തുഷ്ട കുടുംബം.', '["വായിക്കുക", "തയ്യൽ", "പാചകം"]'
);
INSERT INTO public.kurichiyar_profiles (
  id, created_at, updated_at, phone, email, full_name, name, age, gender, dob, photo_url,
  father_tharavadu, mother_tharavadu, father_clan_id, mother_clan_id, district, state,
  about_me, education_level, occupation, income, registration_status, status, approval_status,
  account_status, subscription_tier, is_dummy, photo_approved, is_banned, is_agent, is_out_of_caste, report_count,
  house_name, blood_group, height_cm, weight_kg, taluk, post_office, pincode, family_details, hobbies
) VALUES (
  '1eec5a08-3629-4612-8329-dd20e23c7ad3', now(), now(), '+919900020021', 'dummy_girl_22@auth.kurichiyar.com', 'സജിത വയലിൽ', 'സജിത വയലിൽ', 22, 'female', '2004-05-05', 'https://noidreeslytswkmsnmcn.supabase.co/storage/v1/object/public/user_documents/profile_photos/placeholder_female.png',
  'തോട്ടായി (എടലകുനി)', 'കരിമ്പിച്ചി (കോടങ്ങേല)', 38, 28, 'വയനാട്', 'Kerala',
  'തയ്യൽ ജോലി ചെയ്യുന്നു. ലളിതമായ സ്വഭാവമുള്ള, നല്ലൊരു ജോലി ഉള്ള ഒരാളെ വിവാഹത്തിന് ആഗ്രഹിക്കുന്നു.', 'എം.എസ്.സി. ബിരുദം', 'ഡ്രൈവർ', '2 ലക്ഷം രൂപ', 'live', 'APPROVED', 'Approved',
  'adminReview', 'Free', true, true, false, false, false, 0,
  'വയലിൽ', 'O+', 165, 47, 'മാനന്തവാടി', 'അമ്പലക്കുന്ന്', '673155', 'മാതാവും പിതാവും ഒരു സഹോദരിയും അടങ്ങുന്ന സന്തുഷ്ട കുടുംബം.', '["വായിക്കുക", "തയ്യൽ", "പാചകം"]'
);
INSERT INTO public.kurichiyar_profiles (
  id, created_at, updated_at, phone, email, full_name, name, age, gender, dob, photo_url,
  father_tharavadu, mother_tharavadu, father_clan_id, mother_clan_id, district, state,
  about_me, education_level, occupation, income, registration_status, status, approval_status,
  account_status, subscription_tier, is_dummy, photo_approved, is_banned, is_agent, is_out_of_caste, report_count,
  house_name, blood_group, height_cm, weight_kg, taluk, post_office, pincode, family_details, hobbies
) VALUES (
  '22ee5a30-390c-4e54-a041-316072ad310d', now(), now(), '+919900020022', 'dummy_girl_23@auth.kurichiyar.com', 'ഷൈനി കോട്ടയിൽ', 'ഷൈനി കോട്ടയിൽ', 21, 'female', '2004-10-07', 'https://noidreeslytswkmsnmcn.supabase.co/storage/v1/object/public/user_documents/profile_photos/placeholder_female.png',
  'ഇടുണി (കിഴക്കുംപാട്ട് - ഇടുണി)', 'വെള്ളരി മിലിയാടി (വെള്ളരി)', 44, 36, 'കോഴിക്കോട്', 'Kerala',
  'വിദ്യാഭ്യാസമുള്ള, ഉത്തരവാദിത്തബോധമുള്ള ഒരു ജീവിതപങ്കാളിയെ ആഗ്രഹിക്കുന്നു. വയനാട്ടിൽ നിന്നുള്ളവർക്ക് മുൻഗണന.', 'ബി.എ. ബിരുദം', 'ഡ്രൈവർ', '4 ലക്ഷം രൂപ', 'live', 'APPROVED', 'Approved',
  'adminReview', 'Free', true, true, false, false, false, 0,
  'കോട്ടയിൽ', 'AB+', 161, 60, 'കൊയിലാണ്ടി', 'കോടുവള്ളി', '673114', 'മാതാവും പിതാവും ഒരു സഹോദരിയും അടങ്ങുന്ന സന്തുഷ്ട കുടുംബം.', '["വായിക്കുക", "തയ്യൽ", "പാചകം"]'
);
INSERT INTO public.kurichiyar_profiles (
  id, created_at, updated_at, phone, email, full_name, name, age, gender, dob, photo_url,
  father_tharavadu, mother_tharavadu, father_clan_id, mother_clan_id, district, state,
  about_me, education_level, occupation, income, registration_status, status, approval_status,
  account_status, subscription_tier, is_dummy, photo_approved, is_banned, is_agent, is_out_of_caste, report_count,
  house_name, blood_group, height_cm, weight_kg, taluk, post_office, pincode, family_details, hobbies
) VALUES (
  '8334d4a7-abba-4ef8-ad5f-138ffbd9987a', now(), now(), '+919900020023', 'dummy_girl_24@auth.kurichiyar.com', 'അനുപമ പടിഞ്ഞാറേവീട്', 'അനുപമ പടിഞ്ഞാറേവീട്', 30, 'female', '1996-01-24', 'https://noidreeslytswkmsnmcn.supabase.co/storage/v1/object/public/user_documents/profile_photos/placeholder_female.png',
  'അതിരും കൊലൻ (പঞ্চേരി)', 'മരടി (പുതുരുതൊമ്പിൽ)', 37, 1, 'വയനാട്', 'Kerala',
  'ബിരുദം കഴിഞ്ഞു സ്വകാര്യ ജോലി ചെയ്യുന്നു. സമാന ചിന്താഗതിയുള്ള ഒരാളെ പങ്കാളിയായി ലഭിക്കാൻ ആഗ്രഹിക്കുന്നു.', 'ജനറൽ നഴ്സിംഗ്', 'софтവെയർ എഞ്ചിനീയർ', '2 ലക്ഷം രൂപ', 'live', 'APPROVED', 'Approved',
  'adminReview', 'Free', true, true, false, false, false, 0,
  'പടിഞ്ഞാറേവീട്', 'O+', 168, 61, 'വൈത്തിരി', 'അമ്പലക്കുന്ന്', '673869', 'മാതാവും പിതാവും ഒരു സഹോദരിയും അടങ്ങുന്ന സന്തുഷ്ട കുടുംബം.', '["വായിക്കുക", "തയ്യൽ", "പാചകം"]'
);
INSERT INTO public.kurichiyar_profiles (
  id, created_at, updated_at, phone, email, full_name, name, age, gender, dob, photo_url,
  father_tharavadu, mother_tharavadu, father_clan_id, mother_clan_id, district, state,
  about_me, education_level, occupation, income, registration_status, status, approval_status,
  account_status, subscription_tier, is_dummy, photo_approved, is_banned, is_agent, is_out_of_caste, report_count,
  house_name, blood_group, height_cm, weight_kg, taluk, post_office, pincode, family_details, hobbies
) VALUES (
  'd85df924-4849-499b-81c5-424087e7518b', now(), now(), '+919900020024', 'dummy_girl_25@auth.kurichiyar.com', 'ആര്യ തെക്കേവീട്', 'ആര്യ തെക്കേവീട്', 25, 'female', '2001-02-24', 'https://noidreeslytswkmsnmcn.supabase.co/storage/v1/object/public/user_documents/profile_photos/placeholder_female.png',
  'കുണ്ടര (കുണ്ടര മൂല)', 'പാലിയേരി (പാലേരി)', 11, 54, 'കണ്ണൂർ', 'Kerala',
  'മാതാപിതാക്കളെയും കുടുംബത്തെയും ഒരുപോലെ സ്നേഹിക്കുന്ന ഒരു പങ്കാളിയെ തേടുന്നു. പരസ്പര ബഹുമാനമുള്ള ജീവിതം നയിക്കാൻ താല്പര്യം.', 'ബി.എസ്.സി. ബിരുദം', 'софтവെയർ എഞ്ചിനീയർ', '4 ലക്ഷം രൂപ', 'live', 'APPROVED', 'Approved',
  'adminReview', 'Free', true, true, false, false, false, 0,
  'തെക്കേവീട്', 'B+', 161, 65, 'ഇരിട്ടി', 'മട്ടന്നൂർ', '673745', 'മാതാവും പിതാവും ഒരു സഹോദരിയും അടങ്ങുന്ന സന്തുഷ്ട കുടുംബം.', '["വായിക്കുക", "തയ്യൽ", "പാചകം"]'
);
INSERT INTO public.kurichiyar_profiles (
  id, created_at, updated_at, phone, email, full_name, name, age, gender, dob, photo_url,
  father_tharavadu, mother_tharavadu, father_clan_id, mother_clan_id, district, state,
  about_me, education_level, occupation, income, registration_status, status, approval_status,
  account_status, subscription_tier, is_dummy, photo_approved, is_banned, is_agent, is_out_of_caste, report_count,
  house_name, blood_group, height_cm, weight_kg, taluk, post_office, pincode, family_details, hobbies
) VALUES (
  '24ae5f4f-89ae-4305-a521-48a78eb4c6b4', now(), now(), '+919900020025', 'dummy_girl_26@auth.kurichiyar.com', 'രേഷ്മ വയലിൽ', 'രേഷ്മ വയലിൽ', 27, 'female', '1998-12-02', 'https://noidreeslytswkmsnmcn.supabase.co/storage/v1/object/public/user_documents/profile_photos/placeholder_female.png',
  'പുത്തൂർ (കൊമ്മയാട്)', 'ചാൽപ്പ (പിൽപ്പിടി - പള്ളിയറ)', 21, 52, 'വയനാട്', 'Kerala',
  'മാതാപിതാക്കളെയും കുടുംബത്തെയും ഒരുപോലെ സ്നേഹിക്കുന്ന ഒരു പങ്കാളിയെ തേടുന്നു. പരസ്പര ബഹുമാനമുള്ള ജീവിതം നയിക്കാൻ താല്പര്യം.', 'എം.സി.എ', 'കൃഷി', '3 ലക്ഷം രൂപ', 'live', 'APPROVED', 'Approved',
  'adminReview', 'Free', true, true, false, false, false, 0,
  'വയലിൽ', 'O+', 154, 53, 'സുൽത്താൻ ബത്തേരി', 'കല്പറ്റ', '673130', 'മാതാവും പിതാവും ഒരു സഹോദരിയും അടങ്ങുന്ന സന്തുഷ്ട കുടുംബം.', '["വായിക്കുക", "തയ്യൽ", "പാചകം"]'
);
INSERT INTO public.kurichiyar_profiles (
  id, created_at, updated_at, phone, email, full_name, name, age, gender, dob, photo_url,
  father_tharavadu, mother_tharavadu, father_clan_id, mother_clan_id, district, state,
  about_me, education_level, occupation, income, registration_status, status, approval_status,
  account_status, subscription_tier, is_dummy, photo_approved, is_banned, is_agent, is_out_of_caste, report_count,
  house_name, blood_group, height_cm, weight_kg, taluk, post_office, pincode, family_details, hobbies
) VALUES (
  '909c4ee4-a206-4bf1-a1a7-2f7ac5233d4a', now(), now(), '+919900020026', 'dummy_girl_27@auth.kurichiyar.com', 'ജിഷ ഇല്ലം', 'ജിഷ ഇല്ലം', 27, 'female', '1999-03-13', 'https://noidreeslytswkmsnmcn.supabase.co/storage/v1/object/public/user_documents/profile_photos/placeholder_female.png',
  'ആനി തലക്കര (ആന്നി)', 'കരിമ്പിച്ചി (കോടങ്ങേല)', 31, 28, 'വയനാട്', 'Kerala',
  'മാതാപിതാക്കളെയും കുടുംബത്തെയും ഒരുപോലെ സ്നേഹിക്കുന്ന ഒരു പങ്കാളിയെ തേടുന്നു. പരസ്പര ബഹുമാനമുള്ള ജീവിതം നയിക്കാൻ താല്പര്യം.', 'എം.എ. ബിരുദം', 'അധ്യാപകൻ', '2 ലക്ഷം രൂപ', 'live', 'APPROVED', 'Approved',
  'adminReview', 'Free', true, true, false, false, false, 0,
  'ഇല്ലം', 'AB+', 164, 51, 'മാനന്തവാടി', 'അമ്പലക്കുന്ന്', '673616', 'മാതാവും പിതാവും ഒരു സഹോദരിയും അടങ്ങുന്ന സന്തുഷ്ട കുടുംബം.', '["വായിക്കുക", "തയ്യൽ", "പാചകം"]'
);
INSERT INTO public.kurichiyar_profiles (
  id, created_at, updated_at, phone, email, full_name, name, age, gender, dob, photo_url,
  father_tharavadu, mother_tharavadu, father_clan_id, mother_clan_id, district, state,
  about_me, education_level, occupation, income, registration_status, status, approval_status,
  account_status, subscription_tier, is_dummy, photo_approved, is_banned, is_agent, is_out_of_caste, report_count,
  house_name, blood_group, height_cm, weight_kg, taluk, post_office, pincode, family_details, hobbies
) VALUES (
  '211ba6b6-0b87-4eee-ad7f-57aa261f3131', now(), now(), '+919900020027', 'dummy_girl_28@auth.kurichiyar.com', 'നിഷ എടക്കുടി', 'നിഷ എടക്കുടി', 31, 'female', '1995-04-19', 'https://noidreeslytswkmsnmcn.supabase.co/storage/v1/object/public/user_documents/profile_photos/placeholder_female.png',
  'കൊടുമ തലക്കര (കെടുംമയിൽ)', 'കോലിയൻ (നിറ്റാര)', 33, 20, 'വയനാട്', 'Kerala',
  'തയ്യൽ ജോലി ചെയ്യുന്നു. ലളിതമായ സ്വഭാവമുള്ള, നല്ലൊരു ജോലി ഉള്ള ഒരാളെ വിവാഹത്തിന് ആഗ്രഹിക്കുന്നു.', 'പ്ലസ് ടു', 'ഡ്രൈവർ', '4 ലക്ഷം രൂപ', 'live', 'APPROVED', 'Approved',
  'adminReview', 'Free', true, true, false, false, false, 0,
  'എടക്കുടി', 'B-', 156, 56, 'സുൽത്താൻ ബത്തേരി', 'കല്പറ്റ', '673728', 'മാതാവും പിതാവും ഒരു സഹോദരിയും അടങ്ങുന്ന സന്തുഷ്ട കുടുംബം.', '["വായിക്കുക", "തയ്യൽ", "പാചകം"]'
);
INSERT INTO public.kurichiyar_profiles (
  id, created_at, updated_at, phone, email, full_name, name, age, gender, dob, photo_url,
  father_tharavadu, mother_tharavadu, father_clan_id, mother_clan_id, district, state,
  about_me, education_level, occupation, income, registration_status, status, approval_status,
  account_status, subscription_tier, is_dummy, photo_approved, is_banned, is_agent, is_out_of_caste, report_count,
  house_name, blood_group, height_cm, weight_kg, taluk, post_office, pincode, family_details, hobbies
) VALUES (
  'b1d519bd-b83d-4596-9174-cc99dcf0a30d', now(), now(), '+919900020028', 'dummy_girl_29@auth.kurichiyar.com', 'സ്മിത എടത്തറ', 'സ്മിത എടത്തറ', 27, 'female', '1999-07-17', 'https://noidreeslytswkmsnmcn.supabase.co/storage/v1/object/public/user_documents/profile_photos/placeholder_female.png',
  'പുതിയിടം ചമ്മിയേരി (പുതിയിടം)', 'പരക്കടൻ (വെള്ളോട്ട്)', 46, 48, 'കോഴിക്കോട്', 'Kerala',
  'കുടുംബസ്നേഹമുള്ള ലളിതമായ ഒരു പെൺകുട്ടിയാണ് ഞാൻ. കുടുംബജീവിതത്തിന് പ്രാധാന്യം നൽകുന്നു. നല്ലൊരു പങ്കാളിയെ അന്വേഷിക്കുന്നു.', 'ബി.എ. ബിരുദം', 'സ്വകാര്യ കമ്പനി ജോലി', '2 ലക്ഷം രൂപ', 'live', 'APPROVED', 'Approved',
  'adminReview', 'Free', true, true, false, false, false, 0,
  'എടത്തറ', 'B-', 155, 53, 'താമരശ്ശേരി', 'പേരാമ്പ്ര', '673951', 'മാതാവും പിതാവും ഒരു സഹോദരിയും അടങ്ങുന്ന സന്തുഷ്ട കുടുംബം.', '["വായിക്കുക", "തയ്യൽ", "പാചകം"]'
);
INSERT INTO public.kurichiyar_profiles (
  id, created_at, updated_at, phone, email, full_name, name, age, gender, dob, photo_url,
  father_tharavadu, mother_tharavadu, father_clan_id, mother_clan_id, district, state,
  about_me, education_level, occupation, income, registration_status, status, approval_status,
  account_status, subscription_tier, is_dummy, photo_approved, is_banned, is_agent, is_out_of_caste, report_count,
  house_name, blood_group, height_cm, weight_kg, taluk, post_office, pincode, family_details, hobbies
) VALUES (
  'd1363d34-3167-41a3-8311-2ee6cf4f0c75', now(), now(), '+919900020029', 'dummy_girl_30@auth.kurichiyar.com', 'അഖില കുന്നിൻമേൽ', 'അഖില കുന്നിൻമേൽ', 20, 'female', '2006-05-09', 'https://noidreeslytswkmsnmcn.supabase.co/storage/v1/object/public/user_documents/profile_photos/placeholder_female.png',
  'ചെന്നാക്കണ്ടൻ വളാടൻ (ഒറ്റമലച്ചി)', 'തോട്ടായി (എടലകുനി)', 6, 38, 'കണ്ണൂർ', 'Kerala',
  'വിദ്യാഭ്യാസമുള്ള, ഉത്തരവാദിത്തബോധമുള്ള ഒരു ജീവിതപങ്കാളിയെ ആഗ്രഹിക്കുന്നു. വയനാട്ടിൽ നിന്നുള്ളവർക്ക് മുൻഗണന.', 'എം.സി.എ', 'ഡ്രൈവർ', '2 ലക്ഷം രൂപ', 'live', 'APPROVED', 'Approved',
  'adminReview', 'Free', true, true, false, false, false, 0,
  'കുന്നിൻമേൽ', 'A-', 162, 51, 'ഇരിട്ടി', 'മട്ടന്നൂർ', '673388', 'മാതാവും പിതാവും ഒരു സഹോദരിയും അടങ്ങുന്ന സന്തുഷ്ട കുടുംബം.', '["വായിക്കുക", "തയ്യൽ", "പാചകം"]'
);
INSERT INTO public.kurichiyar_profiles (
  id, created_at, updated_at, phone, email, full_name, name, age, gender, dob, photo_url,
  father_tharavadu, mother_tharavadu, father_clan_id, mother_clan_id, district, state,
  about_me, education_level, occupation, income, registration_status, status, approval_status,
  account_status, subscription_tier, is_dummy, photo_approved, is_banned, is_agent, is_out_of_caste, report_count,
  house_name, blood_group, height_cm, weight_kg, taluk, post_office, pincode, family_details, hobbies
) VALUES (
  '29c3316b-b97c-46a5-a9a8-ed281b93c5e5', now(), now(), '+919900020030', 'dummy_girl_31@auth.kurichiyar.com', 'കാർത്തിക വടക്കേവീട്', 'കാർത്തിക വടക്കേവീട്', 25, 'female', '2001-02-05', 'https://noidreeslytswkmsnmcn.supabase.co/storage/v1/object/public/user_documents/profile_photos/placeholder_female.png',
  'എടപ്പിടി (എടപ്പിടി)', 'കൂടൻ (വളമടക്കിൽ)', 15, 12, 'കോഴിക്കോട്', 'Kerala',
  'മാതാപിതാക്കളെയും കുടുംബത്തെയും ഒരുപോലെ സ്നേഹിക്കുന്ന ഒരു പങ്കാളിയെ തേടുന്നു. പരസ്പര ബഹുമാനമുള്ള ജീവിതം നയിക്കാൻ താല്പര്യം.', 'എം.സി.എ', 'വ്യാപാരി', '2 ലക്ഷം രൂപ', 'live', 'APPROVED', 'Approved',
  'adminReview', 'Free', true, true, false, false, false, 0,
  'വടക്കേവീട്', 'A+', 161, 48, 'താമരശ്ശേരി', 'ബാലുശ്ശേരി', '673248', 'മാതാവും പിതാവും ഒരു സഹോദരിയും അടങ്ങുന്ന സന്തുഷ്ട കുടുംബം.', '["വായിക്കുക", "തയ്യൽ", "പാചകം"]'
);
INSERT INTO public.kurichiyar_profiles (
  id, created_at, updated_at, phone, email, full_name, name, age, gender, dob, photo_url,
  father_tharavadu, mother_tharavadu, father_clan_id, mother_clan_id, district, state,
  about_me, education_level, occupation, income, registration_status, status, approval_status,
  account_status, subscription_tier, is_dummy, photo_approved, is_banned, is_agent, is_out_of_caste, report_count,
  house_name, blood_group, height_cm, weight_kg, taluk, post_office, pincode, family_details, hobbies
) VALUES (
  '870c5838-46b8-4266-b0df-848c45f9ce1a', now(), now(), '+919900020031', 'dummy_girl_32@auth.kurichiyar.com', 'കീർത്തന ഓലിക്കൽ', 'കീർത്തന ഓലിക്കൽ', 23, 'female', '2003-02-09', 'https://noidreeslytswkmsnmcn.supabase.co/storage/v1/object/public/user_documents/profile_photos/placeholder_female.png',
  'ചെന്നാക്കണ്ടൻ വളാടൻ (ഒറ്റമലച്ചി)', 'കൊടിയേരി (പൂലായ്ക്കൽ)', 6, 26, 'കോഴിക്കോട്', 'Kerala',
  'മാതാപിതാക്കളെയും കുടുംബത്തെയും ഒരുപോലെ സ്നേഹിക്കുന്ന ഒരു പങ്കാളിയെ തേടുന്നു. പരസ്പര ബഹുമാനമുള്ള ജീവിതം നയിക്കാൻ താല്പര്യം.', 'എം.സി.എ', 'ഡ്രൈവർ', '1 ലക്ഷം രൂപ', 'live', 'APPROVED', 'Approved',
  'adminReview', 'Free', true, true, false, false, false, 0,
  'ഓലിക്കൽ', 'A-', 158, 52, 'കൊയിലാണ്ടി', 'കോടുവള്ളി', '673959', 'മാതാവും പിതാവും ഒരു സഹോദരിയും അടങ്ങുന്ന സന്തുഷ്ട കുടുംബം.', '["വായിക്കുക", "തയ്യൽ", "പാചകം"]'
);
INSERT INTO public.kurichiyar_profiles (
  id, created_at, updated_at, phone, email, full_name, name, age, gender, dob, photo_url,
  father_tharavadu, mother_tharavadu, father_clan_id, mother_clan_id, district, state,
  about_me, education_level, occupation, income, registration_status, status, approval_status,
  account_status, subscription_tier, is_dummy, photo_approved, is_banned, is_agent, is_out_of_caste, report_count,
  house_name, blood_group, height_cm, weight_kg, taluk, post_office, pincode, family_details, hobbies
) VALUES (
  'ae802044-3343-4b83-acb8-40d0ccd97fd5', now(), now(), '+919900020032', 'dummy_girl_33@auth.kurichiyar.com', 'ഗ്രീഷ്മ വടക്കേവീട്', 'ഗ്രീഷ്മ വടക്കേവീട്', 21, 'female', '2005-02-20', 'https://noidreeslytswkmsnmcn.supabase.co/storage/v1/object/public/user_documents/profile_photos/placeholder_female.png',
  'എരിശേരി (ചേരള)', 'എടത്തണ (എടത്തണ)', 50, 7, 'വയനാട്', 'Kerala',
  'തയ്യൽ ജോലി ചെയ്യുന്നു. ലളിതമായ സ്വഭാവമുള്ള, നല്ലൊരു ജോലി ഉള്ള ഒരാളെ വിവാഹത്തിന് ആഗ്രഹിക്കുന്നു.', 'ബി.ടെക് എഞ്ചിനീയറിംഗ്', 'ഡ്രൈവർ', '2 ലക്ഷം രൂപ', 'live', 'APPROVED', 'Approved',
  'adminReview', 'Free', true, true, false, false, false, 0,
  'വടക്കേവീട്', 'B-', 168, 57, 'സുൽത്താൻ ബത്തേരി', 'മീനങ്ങാടി', '673567', 'മാതാവും പിതാവും ഒരു സഹോദരിയും അടങ്ങുന്ന സന്തുഷ്ട കുടുംബം.', '["വായിക്കുക", "തയ്യൽ", "പാചകം"]'
);
INSERT INTO public.kurichiyar_profiles (
  id, created_at, updated_at, phone, email, full_name, name, age, gender, dob, photo_url,
  father_tharavadu, mother_tharavadu, father_clan_id, mother_clan_id, district, state,
  about_me, education_level, occupation, income, registration_status, status, approval_status,
  account_status, subscription_tier, is_dummy, photo_approved, is_banned, is_agent, is_out_of_caste, report_count,
  house_name, blood_group, height_cm, weight_kg, taluk, post_office, pincode, family_details, hobbies
) VALUES (
  'aa5b22bb-2d0a-4b7f-b01f-473868c7cd4f', now(), now(), '+919900020033', 'dummy_girl_34@auth.kurichiyar.com', 'അനഘ തെക്കേവീട്', 'അനഘ തെക്കേവീട്', 21, 'female', '2004-10-22', 'https://noidreeslytswkmsnmcn.supabase.co/storage/v1/object/public/user_documents/profile_photos/placeholder_female.png',
  'ചേരക്കര (കോലിമൂല)', 'വളാടൻ (ഇല്ലത്തുമൂല)', 8, 5, 'വയനാട്', 'Kerala',
  'ബിരുദം കഴിഞ്ഞു സ്വകാര്യ ജോലി ചെയ്യുന്നു. സമാന ചിന്താഗതിയുള്ള ഒരാളെ പങ്കാളിയായി ലഭിക്കാൻ ആഗ്രഹിക്കുന്നു.', 'എം.സി.എ', 'софтവെയർ എഞ്ചിനീയർ', '4 ലക്ഷം രൂപ', 'live', 'APPROVED', 'Approved',
  'adminReview', 'Free', true, true, false, false, false, 0,
  'തെക്കേവീട്', 'O+', 160, 46, 'മാനന്തവാടി', 'മീനങ്ങാടി', '673970', 'മാതാവും പിതാവും ഒരു സഹോദരിയും അടങ്ങുന്ന സന്തുഷ്ട കുടുംബം.', '["വായിക്കുക", "തയ്യൽ", "പാചകം"]'
);
INSERT INTO public.kurichiyar_profiles (
  id, created_at, updated_at, phone, email, full_name, name, age, gender, dob, photo_url,
  father_tharavadu, mother_tharavadu, father_clan_id, mother_clan_id, district, state,
  about_me, education_level, occupation, income, registration_status, status, approval_status,
  account_status, subscription_tier, is_dummy, photo_approved, is_banned, is_agent, is_out_of_caste, report_count,
  house_name, blood_group, height_cm, weight_kg, taluk, post_office, pincode, family_details, hobbies
) VALUES (
  '18d1fab1-9fa9-4094-a93d-2fa1c70a7f50', now(), now(), '+919900020034', 'dummy_girl_35@auth.kurichiyar.com', 'അഞ്ജലി ചാലിൽ', 'അഞ്ജലി ചാലിൽ', 23, 'female', '2002-12-23', 'https://noidreeslytswkmsnmcn.supabase.co/storage/v1/object/public/user_documents/profile_photos/placeholder_female.png',
  'എരിശേരി (ചേരള)', 'തോട്ടായി (എടലകുനി)', 50, 38, 'വയനാട്', 'Kerala',
  'മാതാപിതാക്കളെയും കുടുംബത്തെയും ഒരുപോലെ സ്നേഹിക്കുന്ന ഒരു പങ്കാളിയെ തേടുന്നു. പരസ്പര ബഹുമാനമുള്ള ജീവിതം നയിക്കാൻ താല്പര്യം.', 'പ്ലസ് ടു', 'സർക്കാർ ജീവനക്കാരൻ', '4 ലക്ഷം രൂപ', 'live', 'APPROVED', 'Approved',
  'adminReview', 'Free', true, true, false, false, false, 0,
  'ചാലിൽ', 'O+', 168, 64, 'മാനന്തവാടി', 'മീനങ്ങാടി', '673449', 'മാതാവും പിതാവും ഒരു സഹോദരിയും അടങ്ങുന്ന സന്തുഷ്ട കുടുംബം.', '["വായിക്കുക", "തയ്യൽ", "പാചകം"]'
);
INSERT INTO public.kurichiyar_profiles (
  id, created_at, updated_at, phone, email, full_name, name, age, gender, dob, photo_url,
  father_tharavadu, mother_tharavadu, father_clan_id, mother_clan_id, district, state,
  about_me, education_level, occupation, income, registration_status, status, approval_status,
  account_status, subscription_tier, is_dummy, photo_approved, is_banned, is_agent, is_out_of_caste, report_count,
  house_name, blood_group, height_cm, weight_kg, taluk, post_office, pincode, family_details, hobbies
) VALUES (
  '6816c332-a78b-4146-b77c-74118e69f2e0', now(), now(), '+919900020035', 'dummy_girl_36@auth.kurichiyar.com', 'ശ്രുതി ഇല്ലം', 'ശ്രുതി ഇല്ലം', 31, 'female', '1995-03-07', 'https://noidreeslytswkmsnmcn.supabase.co/storage/v1/object/public/user_documents/profile_photos/placeholder_female.png',
  'പൂരിഞ്ഞി മിലിയാടി (പൂരിഞ്ഞിൽ)', 'പുത്തൂർ (കൊമ്മയാട്)', 34, 21, 'കണ്ണൂർ', 'Kerala',
  'ബിരുദം കഴിഞ്ഞു സ്വകാര്യ ജോലി ചെയ്യുന്നു. സമാന ചിന്താഗതിയുള്ള ഒരാളെ പങ്കാളിയായി ലഭിക്കാൻ ആഗ്രഹിക്കുന്നു.', 'ബി.എ. ബിരുദം', 'സ്റ്റാഫ് നഴ്സ്', '2 ലക്ഷം രൂപ', 'live', 'APPROVED', 'Approved',
  'adminReview', 'Free', true, true, false, false, false, 0,
  'ഇല്ലം', 'B+', 151, 46, 'ഇരിട്ടി', 'കേളകം', '673713', 'മാതാവും പിതാവും ഒരു സഹോദരിയും അടങ്ങുന്ന സന്തുഷ്ട കുടുംബം.', '["വായിക്കുക", "തയ്യൽ", "പാചകം"]'
);
INSERT INTO public.kurichiyar_profiles (
  id, created_at, updated_at, phone, email, full_name, name, age, gender, dob, photo_url,
  father_tharavadu, mother_tharavadu, father_clan_id, mother_clan_id, district, state,
  about_me, education_level, occupation, income, registration_status, status, approval_status,
  account_status, subscription_tier, is_dummy, photo_approved, is_banned, is_agent, is_out_of_caste, report_count,
  house_name, blood_group, height_cm, weight_kg, taluk, post_office, pincode, family_details, hobbies
) VALUES (
  '38921965-6d1c-4cc4-9fef-6e6cf27f663b', now(), now(), '+919900020036', 'dummy_girl_37@auth.kurichiyar.com', 'ശില്പ എടത്തറ', 'ശില്പ എടത്തറ', 22, 'female', '2003-10-25', 'https://noidreeslytswkmsnmcn.supabase.co/storage/v1/object/public/user_documents/profile_photos/placeholder_female.png',
  'മങ്ങാനി പുത്തൂർ (മങ്ങാനി)', 'എടത്തണ (എടത്തണ)', 22, 7, 'കണ്ണൂർ', 'Kerala',
  'കുടുംബസ്നേഹമുള്ള ലളിതമായ ഒരു പെൺകുട്ടിയാണ് ഞാൻ. കുടുംബജീവിതത്തിന് പ്രാധാന്യം നൽകുന്നു. നല്ലൊരു പങ്കാളിയെ അന്വേഷിക്കുന്നു.', 'പ്ലസ് ടു', 'സ്വകാര്യ കമ്പനി ജോലി', '2 ലക്ഷം രൂപ', 'live', 'APPROVED', 'Approved',
  'adminReview', 'Free', true, true, false, false, false, 0,
  'എടത്തറ', 'O+', 150, 46, 'തലശ്ശേരി', 'കേളകം', '673778', 'മാതാവും പിതാവും ഒരു സഹോദരിയും അടങ്ങുന്ന സന്തുഷ്ട കുടുംബം.', '["വായിക്കുക", "തയ്യൽ", "പാചകം"]'
);
INSERT INTO public.kurichiyar_profiles (
  id, created_at, updated_at, phone, email, full_name, name, age, gender, dob, photo_url,
  father_tharavadu, mother_tharavadu, father_clan_id, mother_clan_id, district, state,
  about_me, education_level, occupation, income, registration_status, status, approval_status,
  account_status, subscription_tier, is_dummy, photo_approved, is_banned, is_agent, is_out_of_caste, report_count,
  house_name, blood_group, height_cm, weight_kg, taluk, post_office, pincode, family_details, hobbies
) VALUES (
  'fa75522f-c756-42ff-a7d8-184618c163dc', now(), now(), '+919900020037', 'dummy_girl_38@auth.kurichiyar.com', 'ശരണ്യ കിഴക്കേവീട്', 'ശരണ്യ കിഴക്കേവീട്', 28, 'female', '1998-03-13', 'https://noidreeslytswkmsnmcn.supabase.co/storage/v1/object/public/user_documents/profile_photos/placeholder_female.png',
  'ഇടുണി (കിഴക്കുംപാട്ട് - ഇടുണി)', 'ചാൽപ്പ (പിൽപ്പിടി - പള്ളിയറ)', 44, 52, 'വയനാട്', 'Kerala',
  'മാതാപിതാക്കളെയും കുടുംബത്തെയും ഒരുപോലെ സ്നേഹിക്കുന്ന ഒരു പങ്കാളിയെ തേടുന്നു. പരസ്പര ബഹുമാനമുള്ള ജീവിതം നയിക്കാൻ താല്പര്യം.', 'എം.ബി.എ', 'സ്റ്റാഫ് നഴ്സ്', '4 ലക്ഷം രൂപ', 'live', 'APPROVED', 'Approved',
  'adminReview', 'Free', true, true, false, false, false, 0,
  'കിഴക്കേവീട്', 'AB+', 162, 47, 'വൈത്തിരി', 'കല്പറ്റ', '673751', 'മാതാവും പിതാവും ഒരു സഹോദരിയും അടങ്ങുന്ന സന്തുഷ്ട കുടുംബം.', '["വായിക്കുക", "തയ്യൽ", "പാചകം"]'
);
INSERT INTO public.kurichiyar_profiles (
  id, created_at, updated_at, phone, email, full_name, name, age, gender, dob, photo_url,
  father_tharavadu, mother_tharavadu, father_clan_id, mother_clan_id, district, state,
  about_me, education_level, occupation, income, registration_status, status, approval_status,
  account_status, subscription_tier, is_dummy, photo_approved, is_banned, is_agent, is_out_of_caste, report_count,
  house_name, blood_group, height_cm, weight_kg, taluk, post_office, pincode, family_details, hobbies
) VALUES (
  '2ded6bc9-5d55-4a6c-9ce4-77b166acd5c0', now(), now(), '+919900020038', 'dummy_girl_39@auth.kurichiyar.com', 'പ്രിയങ്ക എടത്തറ', 'പ്രിയങ്ക എടത്തറ', 27, 'female', '1999-03-27', 'https://noidreeslytswkmsnmcn.supabase.co/storage/v1/object/public/user_documents/profile_photos/placeholder_female.png',
  'തോട്ടായി (എടലകുനി)', 'മങ്ങാനി പുത്തൂർ (മങ്ങാനി)', 38, 22, 'കണ്ണൂർ', 'Kerala',
  'മാതാപിതാക്കളെയും കുടുംബത്തെയും ഒരുപോലെ സ്നേഹിക്കുന്ന ഒരു പങ്കാളിയെ തേടുന്നു. പരസ്പര ബഹുമാനമുള്ള ജീവിതം നയിക്കാൻ താല്പര്യം.', 'എം.എ. ബിരുദം', 'ഡ്രൈവർ', '1 ലക്ഷം രൂപ', 'live', 'APPROVED', 'Approved',
  'adminReview', 'Free', true, true, false, false, false, 0,
  'എടത്തറ', 'O+', 163, 64, 'തളിപ്പറമ്പ്', 'മട്ടന്നൂർ', '673146', 'മാതാവും പിതാവും ഒരു സഹോദരിയും അടങ്ങുന്ന സന്തുഷ്ട കുടുംബം.', '["വായിക്കുക", "തയ്യൽ", "പാചകം"]'
);
INSERT INTO public.kurichiyar_profiles (
  id, created_at, updated_at, phone, email, full_name, name, age, gender, dob, photo_url,
  father_tharavadu, mother_tharavadu, father_clan_id, mother_clan_id, district, state,
  about_me, education_level, occupation, income, registration_status, status, approval_status,
  account_status, subscription_tier, is_dummy, photo_approved, is_banned, is_agent, is_out_of_caste, report_count,
  house_name, blood_group, height_cm, weight_kg, taluk, post_office, pincode, family_details, hobbies
) VALUES (
  '1f89b8a9-8b2d-45a6-b346-5dd129b9e0ee', now(), now(), '+919900020039', 'dummy_girl_40@auth.kurichiyar.com', 'അർച്ചന മീത്തൽ', 'അർച്ചന മീത്തൽ', 25, 'female', '2000-08-10', 'https://noidreeslytswkmsnmcn.supabase.co/storage/v1/object/public/user_documents/profile_photos/placeholder_female.png',
  'എടത്തണ (എടത്തണ)', 'മൂത്തേടൻ (മൂത്തേടത്ത്)', 7, 27, 'വയനാട്', 'Kerala',
  'കുടുംബസ്നേഹമുള്ള ലളിതമായ ഒരു പെൺകുട്ടിയാണ് ഞാൻ. കുടുംബജീവിതത്തിന് പ്രാധാന്യം നൽകുന്നു. നല്ലൊരു പങ്കാളിയെ അന്വേഷിക്കുന്നു.', 'എം.എ. ബിരുദം', 'കൃഷി', '3 ലക്ഷം രൂപ', 'live', 'APPROVED', 'Approved',
  'adminReview', 'Free', true, true, false, false, false, 0,
  'മീത്തൽ', 'B-', 160, 61, 'വൈത്തിരി', 'അമ്പലക്കുന്ന്', '673339', 'മാതാവും പിതാവും ഒരു സഹോദരിയും അടങ്ങുന്ന സന്തുഷ്ട കുടുംബം.', '["വായിക്കുക", "തയ്യൽ", "പാചകം"]'
);
INSERT INTO public.kurichiyar_profiles (
  id, created_at, updated_at, phone, email, full_name, name, age, gender, dob, photo_url,
  father_tharavadu, mother_tharavadu, father_clan_id, mother_clan_id, district, state,
  about_me, education_level, occupation, income, registration_status, status, approval_status,
  account_status, subscription_tier, is_dummy, photo_approved, is_banned, is_agent, is_out_of_caste, report_count,
  house_name, blood_group, height_cm, weight_kg, taluk, post_office, pincode, family_details, hobbies
) VALUES (
  '1ca37662-a75f-48b9-b0bb-aa67d689e736', now(), now(), '+919900020040', 'dummy_girl_41@auth.kurichiyar.com', 'വിദ്യ ചാലിൽ', 'വിദ്യ ചാലിൽ', 24, 'female', '2002-03-07', 'https://noidreeslytswkmsnmcn.supabase.co/storage/v1/object/public/user_documents/profile_photos/placeholder_female.png',
  'തെറ്റ (വേങ്ങലോട്ട്)', 'നെല്ലുകുടിയൻ (കാക്കോത്തറ)', 40, 4, 'കണ്ണൂർ', 'Kerala',
  'കുടുംബസ്നേഹമുള്ള ലളിതമായ ഒരു പെൺകുട്ടിയാണ് ഞാൻ. കുടുംബജീവിതത്തിന് പ്രാധാന്യം നൽകുന്നു. നല്ലൊരു പങ്കാളിയെ അന്വേഷിക്കുന്നു.', 'ബി.കോം ബിരുദം', 'софтവെയർ എഞ്ചിനീയർ', '3 ലക്ഷം രൂപ', 'live', 'APPROVED', 'Approved',
  'adminReview', 'Free', true, true, false, false, false, 0,
  'ചാലിൽ', 'AB+', 156, 49, 'തലശ്ശേരി', 'മട്ടന്നൂർ', '673290', 'മാതാവും പിതാവും ഒരു സഹോദരിയും അടങ്ങുന്ന സന്തുഷ്ട കുടുംബം.', '["വായിക്കുക", "തയ്യൽ", "പാചകം"]'
);
INSERT INTO public.kurichiyar_profiles (
  id, created_at, updated_at, phone, email, full_name, name, age, gender, dob, photo_url,
  father_tharavadu, mother_tharavadu, father_clan_id, mother_clan_id, district, state,
  about_me, education_level, occupation, income, registration_status, status, approval_status,
  account_status, subscription_tier, is_dummy, photo_approved, is_banned, is_agent, is_out_of_caste, report_count,
  house_name, blood_group, height_cm, weight_kg, taluk, post_office, pincode, family_details, hobbies
) VALUES (
  '09afadcf-bd24-4275-9816-aa0b70c6ca59', now(), now(), '+919900020041', 'dummy_girl_42@auth.kurichiyar.com', 'പ്രസീത വയലിൽ', 'പ്രസീത വയലിൽ', 29, 'female', '1997-07-11', 'https://noidreeslytswkmsnmcn.supabase.co/storage/v1/object/public/user_documents/profile_photos/placeholder_female.png',
  'പാലോടൻ (പാലോട്ട്)', 'പടനി (കുഴികണ്ടം)', 16, 53, 'വയനാട്', 'Kerala',
  'മാതാപിതാക്കളെയും കുടുംബത്തെയും ഒരുപോലെ സ്നേഹിക്കുന്ന ഒരു പങ്കാളിയെ തേടുന്നു. പരസ്പര ബഹുമാനമുള്ള ജീവിതം നയിക്കാൻ താല്പര്യം.', 'എം.എ. ബിരുദം', 'സർക്കാർ ജീവനക്കാരൻ', '1 ലക്ഷം രൂപ', 'live', 'APPROVED', 'Approved',
  'adminReview', 'Free', true, true, false, false, false, 0,
  'വയലിൽ', 'AB+', 158, 60, 'മാനന്തവാടി', 'അമ്പലക്കുന്ന്', '673616', 'മാതാവും പിതാവും ഒരു സഹോദരിയും അടങ്ങുന്ന സന്തുഷ്ട കുടുംബം.', '["വായിക്കുക", "തയ്യൽ", "പാചകം"]'
);
INSERT INTO public.kurichiyar_profiles (
  id, created_at, updated_at, phone, email, full_name, name, age, gender, dob, photo_url,
  father_tharavadu, mother_tharavadu, father_clan_id, mother_clan_id, district, state,
  about_me, education_level, occupation, income, registration_status, status, approval_status,
  account_status, subscription_tier, is_dummy, photo_approved, is_banned, is_agent, is_out_of_caste, report_count,
  house_name, blood_group, height_cm, weight_kg, taluk, post_office, pincode, family_details, hobbies
) VALUES (
  '1068e893-390c-4447-a2d6-cc58866b4610', now(), now(), '+919900020042', 'dummy_girl_43@auth.kurichiyar.com', 'ശ്രീജ പുത്തൻവീട്', 'ശ്രീജ പുത്തൻവീട്', 25, 'female', '2001-03-30', 'https://noidreeslytswkmsnmcn.supabase.co/storage/v1/object/public/user_documents/profile_photos/placeholder_female.png',
  'കുക്കോടൻ (കുക്കോട്ടിൽ)', 'കാക്കിലി (ഓടുടുമ്പിൽ)', 55, 47, 'കോഴിക്കോട്', 'Kerala',
  'വിദ്യാഭ്യാസമുള്ള, ഉത്തരവാദിത്തബോധമുള്ള ഒരു ജീവിതപങ്കാളിയെ ആഗ്രഹിക്കുന്നു. വയനാട്ടിൽ നിന്നുള്ളവർക്ക് മുൻഗണന.', 'പ്ലസ് ടു', 'കൃഷി', '1 ലക്ഷം രൂപ', 'live', 'APPROVED', 'Approved',
  'adminReview', 'Free', true, true, false, false, false, 0,
  'പുത്തൻവീട്', 'A-', 161, 53, 'വടകര', 'കോടുവള്ളി', '673886', 'മാതാവും പിതാവും ഒരു സഹോദരിയും അടങ്ങുന്ന സന്തുഷ്ട കുടുംബം.', '["വായിക്കുക", "തയ്യൽ", "പാചകം"]'
);
INSERT INTO public.kurichiyar_profiles (
  id, created_at, updated_at, phone, email, full_name, name, age, gender, dob, photo_url,
  father_tharavadu, mother_tharavadu, father_clan_id, mother_clan_id, district, state,
  about_me, education_level, occupation, income, registration_status, status, approval_status,
  account_status, subscription_tier, is_dummy, photo_approved, is_banned, is_agent, is_out_of_caste, report_count,
  house_name, blood_group, height_cm, weight_kg, taluk, post_office, pincode, family_details, hobbies
) VALUES (
  'ab3427a5-eae0-4a92-9fe3-fb0e316ff30a', now(), now(), '+919900020043', 'dummy_girl_44@auth.kurichiyar.com', 'സിനി പുത്തൻവീട്', 'സിനി പുത്തൻവീട്', 23, 'female', '2003-03-10', 'https://noidreeslytswkmsnmcn.supabase.co/storage/v1/object/public/user_documents/profile_photos/placeholder_female.png',
  'കുനിമൽ മിലിയാടി (കുനിയമ്മൽ)', 'വെണ്ണിയോറ (വെണ്ണിയോറ)', 35, 23, 'വയനാട്', 'Kerala',
  'കുടുംബസ്നേഹമുള്ള ലളിതമായ ഒരു പെൺകുട്ടിയാണ് ഞാൻ. കുടുംബജീവിതത്തിന് പ്രാധാന്യം നൽകുന്നു. നല്ലൊരു പങ്കാളിയെ അന്വേഷിക്കുന്നു.', 'ബി.എസ്.സി. ബിരുദം', 'സർക്കാർ ജീവനക്കാരൻ', '3 ലക്ഷം രൂപ', 'live', 'APPROVED', 'Approved',
  'adminReview', 'Free', true, true, false, false, false, 0,
  'പുത്തൻവീട്', 'O+', 166, 50, 'മാനന്തവാടി', 'അമ്പലക്കുന്ന്', '673283', 'മാതാവും പിതാവും ഒരു സഹോദരിയും അടങ്ങുന്ന സന്തുഷ്ട കുടുംബം.', '["വായിക്കുക", "തയ്യൽ", "പാചകം"]'
);
INSERT INTO public.kurichiyar_profiles (
  id, created_at, updated_at, phone, email, full_name, name, age, gender, dob, photo_url,
  father_tharavadu, mother_tharavadu, father_clan_id, mother_clan_id, district, state,
  about_me, education_level, occupation, income, registration_status, status, approval_status,
  account_status, subscription_tier, is_dummy, photo_approved, is_banned, is_agent, is_out_of_caste, report_count,
  house_name, blood_group, height_cm, weight_kg, taluk, post_office, pincode, family_details, hobbies
) VALUES (
  'f82134a4-1391-4aa6-9575-07e5cc735e6e', now(), now(), '+919900020044', 'dummy_girl_45@auth.kurichiyar.com', 'ഷീബ മീത്തൽ', 'ഷീബ മീത്തൽ', 31, 'female', '1995-03-04', 'https://noidreeslytswkmsnmcn.supabase.co/storage/v1/object/public/user_documents/profile_photos/placeholder_female.png',
  'ചെരൂല് (മേനരത്ത്)', 'ചാൽപ്പ (പിൽപ്പിടി - പള്ളിയറ)', 49, 52, 'കണ്ണൂർ', 'Kerala',
  'വിദ്യാഭ്യാസമുള്ള, ഉത്തരവാദിത്തബോധമുള്ള ഒരു ജീവിതപങ്കാളിയെ ആഗ്രഹിക്കുന്നു. വയനാട്ടിൽ നിന്നുള്ളവർക്ക് മുൻഗണന.', 'പ്ലസ് ടു', 'അധ്യാപകൻ', '3 ലക്ഷം രൂപ', 'live', 'APPROVED', 'Approved',
  'adminReview', 'Free', true, true, false, false, false, 0,
  'മീത്തൽ', 'A+', 166, 53, 'ഇരിട്ടി', 'മട്ടന്നൂർ', '673883', 'മാതാവും പിതാവും ഒരു സഹോദരിയും അടങ്ങുന്ന സന്തുഷ്ട കുടുംബം.', '["വായിക്കുക", "തയ്യൽ", "പാചകം"]'
);
INSERT INTO public.kurichiyar_profiles (
  id, created_at, updated_at, phone, email, full_name, name, age, gender, dob, photo_url,
  father_tharavadu, mother_tharavadu, father_clan_id, mother_clan_id, district, state,
  about_me, education_level, occupation, income, registration_status, status, approval_status,
  account_status, subscription_tier, is_dummy, photo_approved, is_banned, is_agent, is_out_of_caste, report_count,
  house_name, blood_group, height_cm, weight_kg, taluk, post_office, pincode, family_details, hobbies
) VALUES (
  '58988464-34f1-434e-accc-22f7b3b93c88', now(), now(), '+919900020045', 'dummy_girl_46@auth.kurichiyar.com', 'മായ മീത്തൽ', 'മായ മീത്തൽ', 22, 'female', '2004-07-06', 'https://noidreeslytswkmsnmcn.supabase.co/storage/v1/object/public/user_documents/profile_photos/placeholder_female.png',
  'ചെറുമ്പാലൻ (കാക്കൻ ചിറ)', 'അതിരും കൊലൻ (പঞ্চേരി)', 24, 37, 'കണ്ണൂർ', 'Kerala',
  'വിദ്യാഭ്യാസമുള്ള, ഉത്തരവാദിത്തബോധമുള്ള ഒരു ജീവിതപങ്കാളിയെ ആഗ്രഹിക്കുന്നു. വയനാട്ടിൽ നിന്നുള്ളവർക്ക് മുൻഗണന.', 'പ്ലസ് ടു', 'വ്യാപാരി', '1 ലക്ഷം രൂപ', 'live', 'APPROVED', 'Approved',
  'adminReview', 'Free', true, true, false, false, false, 0,
  'മീത്തൽ', 'B-', 159, 47, 'ഇരിട്ടി', 'കേളകം', '673215', 'മാതാവും പിതാവും ഒരു സഹോദരിയും അടങ്ങുന്ന സന്തുഷ്ട കുടുംബം.', '["വായിക്കുക", "തയ്യൽ", "പാചകം"]'
);
INSERT INTO public.kurichiyar_profiles (
  id, created_at, updated_at, phone, email, full_name, name, age, gender, dob, photo_url,
  father_tharavadu, mother_tharavadu, father_clan_id, mother_clan_id, district, state,
  about_me, education_level, occupation, income, registration_status, status, approval_status,
  account_status, subscription_tier, is_dummy, photo_approved, is_banned, is_agent, is_out_of_caste, report_count,
  house_name, blood_group, height_cm, weight_kg, taluk, post_office, pincode, family_details, hobbies
) VALUES (
  '3c1dd82e-0c5b-45bd-9746-54768f5bccd5', now(), now(), '+919900020046', 'dummy_girl_47@auth.kurichiyar.com', 'വിജിത വടക്കേവീട്', 'വിജിത വടക്കേവീട്', 25, 'female', '2000-12-30', 'https://noidreeslytswkmsnmcn.supabase.co/storage/v1/object/public/user_documents/profile_photos/placeholder_female.png',
  'ആനി തലക്കര (ആന്നി)', 'കല്ലാറ കരിമ്പിച്ചി (പറമ്മൂല)', 31, 30, 'വയനാട്', 'Kerala',
  'കുടുംബസ്നേഹമുള്ള ലളിതമായ ഒരു പെൺകുട്ടിയാണ് ഞാൻ. കുടുംബജീവിതത്തിന് പ്രാധാന്യം നൽകുന്നു. നല്ലൊരു പങ്കാളിയെ അന്വേഷിക്കുന്നു.', 'ജനറൽ നഴ്സിംഗ്', 'софтവെയർ എഞ്ചിനീയർ', '2 ലക്ഷം രൂപ', 'live', 'APPROVED', 'Approved',
  'adminReview', 'Free', true, true, false, false, false, 0,
  'വടക്കേവീട്', 'AB+', 167, 62, 'സുൽത്താൻ ബത്തേരി', 'മീനങ്ങാടി', '673659', 'മാതാവും പിതാവും ഒരു സഹോദരിയും അടങ്ങുന്ന സന്തുഷ്ട കുടുംബം.', '["വായിക്കുക", "തയ്യൽ", "പാചകം"]'
);
INSERT INTO public.kurichiyar_profiles (
  id, created_at, updated_at, phone, email, full_name, name, age, gender, dob, photo_url,
  father_tharavadu, mother_tharavadu, father_clan_id, mother_clan_id, district, state,
  about_me, education_level, occupation, income, registration_status, status, approval_status,
  account_status, subscription_tier, is_dummy, photo_approved, is_banned, is_agent, is_out_of_caste, report_count,
  house_name, blood_group, height_cm, weight_kg, taluk, post_office, pincode, family_details, hobbies
) VALUES (
  '9e8aa729-828a-40e0-b2c9-e86d04c2870d', now(), now(), '+919900020047', 'dummy_girl_48@auth.kurichiyar.com', 'അംബിക പാലക്കൽ', 'അംബിക പാലക്കൽ', 28, 'female', '1998-07-09', 'https://noidreeslytswkmsnmcn.supabase.co/storage/v1/object/public/user_documents/profile_photos/placeholder_female.png',
  'ചെന്നാക്കണ്ടൻ വളാടൻ (ഒറ്റമലച്ചി)', 'പൂരിഞ്ഞി മിലിയാടി (പൂരിഞ്ഞിൽ)', 6, 34, 'കണ്ണൂർ', 'Kerala',
  'ബിരുദം കഴിഞ്ഞു സ്വകാര്യ ജോലി ചെയ്യുന്നു. സമാന ചിന്താഗതിയുള്ള ഒരാളെ പങ്കാളിയായി ലഭിക്കാൻ ആഗ്രഹിക്കുന്നു.', 'എം.ബി.എ', 'സർക്കാർ ജീവനക്കാരൻ', '3 ലക്ഷം രൂപ', 'live', 'APPROVED', 'Approved',
  'adminReview', 'Free', true, true, false, false, false, 0,
  'പാലക്കൽ', 'AB+', 151, 45, 'തലശ്ശേരി', 'കേളകം', '673738', 'മാതാവും പിതാവും ഒരു സഹോദരിയും അടങ്ങുന്ന സന്തുഷ്ട കുടുംബം.', '["വായിക്കുക", "തയ്യൽ", "പാചകം"]'
);
INSERT INTO public.kurichiyar_profiles (
  id, created_at, updated_at, phone, email, full_name, name, age, gender, dob, photo_url,
  father_tharavadu, mother_tharavadu, father_clan_id, mother_clan_id, district, state,
  about_me, education_level, occupation, income, registration_status, status, approval_status,
  account_status, subscription_tier, is_dummy, photo_approved, is_banned, is_agent, is_out_of_caste, report_count,
  house_name, blood_group, height_cm, weight_kg, taluk, post_office, pincode, family_details, hobbies
) VALUES (
  'aa43d84d-01f0-4952-804b-d8aac6f25c07', now(), now(), '+919900020048', 'dummy_girl_49@auth.kurichiyar.com', 'യമുന ഇല്ലം', 'യമുന ഇല്ലം', 27, 'female', '1999-06-13', 'https://noidreeslytswkmsnmcn.supabase.co/storage/v1/object/public/user_documents/profile_photos/placeholder_female.png',
  'കോലിയൻ (നിറ്റാര)', 'പാലിയേരി (പാലേരി)', 20, 54, 'വയനാട്', 'Kerala',
  'തയ്യൽ ജോലി ചെയ്യുന്നു. ലളിതമായ സ്വഭാവമുള്ള, നല്ലൊരു ജോലി ഉള്ള ഒരാളെ വിവാഹത്തിന് ആഗ്രഹിക്കുന്നു.', 'ബി.ടെക് എഞ്ചിനീയറിംഗ്', 'അധ്യാപകൻ', '1 ലക്ഷം രൂപ', 'live', 'APPROVED', 'Approved',
  'adminReview', 'Free', true, true, false, false, false, 0,
  'ഇല്ലം', 'AB+', 166, 54, 'സുൽത്താൻ ബത്തേരി', 'മീനങ്ങാടി', '673194', 'മാതാവും പിതാവും ഒരു സഹോദരിയും അടങ്ങുന്ന സന്തുഷ്ട കുടുംബം.', '["വായിക്കുക", "തയ്യൽ", "പാചകം"]'
);
INSERT INTO public.kurichiyar_profiles (
  id, created_at, updated_at, phone, email, full_name, name, age, gender, dob, photo_url,
  father_tharavadu, mother_tharavadu, father_clan_id, mother_clan_id, district, state,
  about_me, education_level, occupation, income, registration_status, status, approval_status,
  account_status, subscription_tier, is_dummy, photo_approved, is_banned, is_agent, is_out_of_caste, report_count,
  house_name, blood_group, height_cm, weight_kg, taluk, post_office, pincode, family_details, hobbies
) VALUES (
  '8ae0c4d1-c7ee-49fe-9a88-5918cbe67c39', now(), now(), '+919900020049', 'dummy_girl_50@auth.kurichiyar.com', 'ശോഭന എടക്കുടി', 'ശോഭന എടക്കുടി', 31, 'female', '1995-02-07', 'https://noidreeslytswkmsnmcn.supabase.co/storage/v1/object/public/user_documents/profile_photos/placeholder_female.png',
  'ചേരക്കര (കോലിമൂല)', 'പുച്ചിയേരി (ചായിമ്മൽ)', 8, 10, 'കോഴിക്കോട്', 'Kerala',
  'വിദ്യാഭ്യാസമുള്ള, ഉത്തരവാദിത്തബോധമുള്ള ഒരു ജീവിതപങ്കാളിയെ ആഗ്രഹിക്കുന്നു. വയനാട്ടിൽ നിന്നുള്ളവർക്ക് മുൻഗണന.', 'പ്ലസ് ടു', 'സ്റ്റാഫ് നഴ്സ്', '3 ലക്ഷം രൂപ', 'live', 'APPROVED', 'Approved',
  'adminReview', 'Free', true, true, false, false, false, 0,
  'എടക്കുടി', 'B-', 158, 62, 'താമരശ്ശേരി', 'പേരാമ്പ്ര', '673639', 'മാതാവും പിതാവും ഒരു സഹോദരിയും അടങ്ങുന്ന സന്തുഷ്ട കുടുംബം.', '["വായിക്കുക", "തയ്യൽ", "പാചകം"]'
);
INSERT INTO public.kurichiyar_profiles (
  id, created_at, updated_at, phone, email, full_name, name, age, gender, dob, photo_url,
  father_tharavadu, mother_tharavadu, father_clan_id, mother_clan_id, district, state,
  about_me, education_level, occupation, income, registration_status, status, approval_status,
  account_status, subscription_tier, is_dummy, photo_approved, is_banned, is_agent, is_out_of_caste, report_count,
  house_name, blood_group, height_cm, weight_kg, taluk, post_office, pincode, family_details, hobbies
) VALUES (
  '390ac9fe-dbd5-4165-a028-83c67d46e5ec', now(), now(), '+919900020050', 'dummy_girl_51@auth.kurichiyar.com', 'ഗിരിജ തറവാട്', 'ഗിരിജ തറവാട്', 21, 'female', '2005-02-18', 'https://noidreeslytswkmsnmcn.supabase.co/storage/v1/object/public/user_documents/profile_photos/placeholder_female.png',
  'ചാൽപ്പ (പിൽപ്പിടി - പള്ളിയറ)', 'പെരിഞ്ചോല (പെരിഞ്ചേ)', 52, 56, 'കോഴിക്കോട്', 'Kerala',
  'ബിരുദം കഴിഞ്ഞു സ്വകാര്യ ജോലി ചെയ്യുന്നു. സമാന ചിന്താഗതിയുള്ള ഒരാളെ പങ്കാളിയായി ലഭിക്കാൻ ആഗ്രഹിക്കുന്നു.', 'എം.എസ്.സി. ബിരുദം', 'സ്വകാര്യ കമ്പനി ജോലി', '2 ലക്ഷം രൂപ', 'live', 'APPROVED', 'Approved',
  'adminReview', 'Free', true, true, false, false, false, 0,
  'തറവാട്', 'A+', 167, 61, 'കൊയിലാണ്ടി', 'പേരാമ്പ്ര', '673726', 'മാതാവും പിതാവും ഒരു സഹോദരിയും അടങ്ങുന്ന സന്തുഷ്ട കുടുംബം.', '["വായിക്കുക", "തയ്യൽ", "പാചകം"]'
);
INSERT INTO public.kurichiyar_profiles (
  id, created_at, updated_at, phone, email, full_name, name, age, gender, dob, photo_url,
  father_tharavadu, mother_tharavadu, father_clan_id, mother_clan_id, district, state,
  about_me, education_level, occupation, income, registration_status, status, approval_status,
  account_status, subscription_tier, is_dummy, photo_approved, is_banned, is_agent, is_out_of_caste, report_count,
  house_name, blood_group, height_cm, weight_kg, taluk, post_office, pincode, family_details, hobbies
) VALUES (
  '9691535f-96cc-4878-80a0-c59ff41585e4', now(), now(), '+919900020051', 'dummy_girl_52@auth.kurichiyar.com', 'മഞ്ജു പടിഞ്ഞാറേവീട്', 'മഞ്ജു പടിഞ്ഞാറേവീട്', 21, 'female', '2004-10-15', 'https://noidreeslytswkmsnmcn.supabase.co/storage/v1/object/public/user_documents/profile_photos/placeholder_female.png',
  'കുക്കോടൻ (കുക്കോട്ടിൽ)', 'തെറ്റ (വേങ്ങലോട്ട്)', 55, 40, 'കണ്ണൂർ', 'Kerala',
  'വിദ്യാഭ്യാസമുള്ള, ഉത്തരവാദിത്തബോധമുള്ള ഒരു ജീവിതപങ്കാളിയെ ആഗ്രഹിക്കുന്നു. വയനാട്ടിൽ നിന്നുള്ളവർക്ക് മുൻഗണന.', 'ബി.എ. ബിരുദം', 'സ്വകാര്യ കമ്പനി ജോലി', '4 ലക്ഷം രൂപ', 'live', 'APPROVED', 'Approved',
  'adminReview', 'Free', true, true, false, false, false, 0,
  'പടിഞ്ഞാറേവീട്', 'A-', 164, 56, 'ഇരിട്ടി', 'പേരാവൂർ', '673181', 'മാതാവും പിതാവും ഒരു സഹോദരിയും അടങ്ങുന്ന സന്തുഷ്ട കുടുംബം.', '["വായിക്കുക", "തയ്യൽ", "പാചകം"]'
);
INSERT INTO public.kurichiyar_profiles (
  id, created_at, updated_at, phone, email, full_name, name, age, gender, dob, photo_url,
  father_tharavadu, mother_tharavadu, father_clan_id, mother_clan_id, district, state,
  about_me, education_level, occupation, income, registration_status, status, approval_status,
  account_status, subscription_tier, is_dummy, photo_approved, is_banned, is_agent, is_out_of_caste, report_count,
  house_name, blood_group, height_cm, weight_kg, taluk, post_office, pincode, family_details, hobbies
) VALUES (
  'ad1c626a-2717-4a1d-b219-955302d1845f', now(), now(), '+919900020052', 'dummy_girl_53@auth.kurichiyar.com', 'ലേഖ എടക്കുടി', 'ലേഖ എടക്കുടി', 20, 'female', '2006-04-27', 'https://noidreeslytswkmsnmcn.supabase.co/storage/v1/object/public/user_documents/profile_photos/placeholder_female.png',
  'പുത്തൂർ (കൊമ്മയാട്)', 'ചേരക്കര (കോലിമൂല)', 21, 8, 'വയനാട്', 'Kerala',
  'മാതാപിതാക്കളെയും കുടുംബത്തെയും ഒരുപോലെ സ്നേഹിക്കുന്ന ഒരു പങ്കാളിയെ തേടുന്നു. പരസ്പര ബഹുമാനമുള്ള ജീവിതം നയിക്കാൻ താല്പര്യം.', 'എം.എസ്.സി. ബിരുദം', 'തയ്യൽ ജോലി', '1 ലക്ഷം രൂപ', 'live', 'APPROVED', 'Approved',
  'adminReview', 'Free', true, true, false, false, false, 0,
  'എടക്കുടി', 'AB+', 163, 47, 'വൈത്തിരി', 'മീനങ്ങാടി', '673826', 'മാതാവും പിതാവും ഒരു സഹോദരിയും അടങ്ങുന്ന സന്തുഷ്ട കുടുംബം.', '["വായിക്കുക", "തയ്യൽ", "പാചകം"]'
);
INSERT INTO public.kurichiyar_profiles (
  id, created_at, updated_at, phone, email, full_name, name, age, gender, dob, photo_url,
  father_tharavadu, mother_tharavadu, father_clan_id, mother_clan_id, district, state,
  about_me, education_level, occupation, income, registration_status, status, approval_status,
  account_status, subscription_tier, is_dummy, photo_approved, is_banned, is_agent, is_out_of_caste, report_count,
  house_name, blood_group, height_cm, weight_kg, taluk, post_office, pincode, family_details, hobbies
) VALUES (
  '34ee87e0-66bf-41e2-a2e5-451b6d347851', now(), now(), '+919900020053', 'dummy_girl_54@auth.kurichiyar.com', 'സുജ മീത്തൽ', 'സുജ മീത്തൽ', 28, 'female', '1998-06-10', 'https://noidreeslytswkmsnmcn.supabase.co/storage/v1/object/public/user_documents/profile_photos/placeholder_female.png',
  'നെല്ലുകുടിയൻ (കാക്കോത്തറ)', 'നെല്ലേരി മരടി (മരടി നെല്ലേരി)', 4, 2, 'കണ്ണൂർ', 'Kerala',
  'വിദ്യാഭ്യാസമുള്ള, ഉത്തരവാദിത്തബോധമുള്ള ഒരു ജീവിതപങ്കാളിയെ ആഗ്രഹിക്കുന്നു. വയനാട്ടിൽ നിന്നുള്ളവർക്ക് മുൻഗണന.', 'ബി.എ. ബിരുദം', 'സർക്കാർ ജീവനക്കാരൻ', '2 ലക്ഷം രൂപ', 'live', 'APPROVED', 'Approved',
  'adminReview', 'Free', true, true, false, false, false, 0,
  'മീത്തൽ', 'O+', 157, 59, 'ഇരിട്ടി', 'പേരാവൂർ', '673426', 'മാതാവും പിതാവും ഒരു സഹോദരിയും അടങ്ങുന്ന സന്തുഷ്ട കുടുംബം.', '["വായിക്കുക", "തയ്യൽ", "പാചകം"]'
);
INSERT INTO public.kurichiyar_profiles (
  id, created_at, updated_at, phone, email, full_name, name, age, gender, dob, photo_url,
  father_tharavadu, mother_tharavadu, father_clan_id, mother_clan_id, district, state,
  about_me, education_level, occupation, income, registration_status, status, approval_status,
  account_status, subscription_tier, is_dummy, photo_approved, is_banned, is_agent, is_out_of_caste, report_count,
  house_name, blood_group, height_cm, weight_kg, taluk, post_office, pincode, family_details, hobbies
) VALUES (
  '44a9f10e-8d79-4935-b545-995af69cde90', now(), now(), '+919900020054', 'dummy_girl_55@auth.kurichiyar.com', 'രജനി പുത്തൻവീട്', 'രജനി പുത്തൻവീട്', 26, 'female', '1999-10-12', 'https://noidreeslytswkmsnmcn.supabase.co/storage/v1/object/public/user_documents/profile_photos/placeholder_female.png',
  'കാക്കിലി (ഓടുടുമ്പിൽ)', 'കൊടിയേരി (പൂലായ്ക്കൽ)', 47, 26, 'കണ്ണൂർ', 'Kerala',
  'തയ്യൽ ജോലി ചെയ്യുന്നു. ലളിതമായ സ്വഭാവമുള്ള, നല്ലൊരു ജോലി ഉള്ള ഒരാളെ വിവാഹത്തിന് ആഗ്രഹിക്കുന്നു.', 'എം.എ. ബിരുദം', 'софтവെയർ എഞ്ചിനീയർ', '3 ലക്ഷം രൂപ', 'live', 'APPROVED', 'Approved',
  'adminReview', 'Free', true, true, false, false, false, 0,
  'പുത്തൻവീട്', 'A+', 150, 55, 'തലശ്ശേരി', 'കേളകം', '673721', 'മാതാവും പിതാവും ഒരു സഹോദരിയും അടങ്ങുന്ന സന്തുഷ്ട കുടുംബം.', '["വായിക്കുക", "തയ്യൽ", "പാചകം"]'
);
INSERT INTO public.kurichiyar_profiles (
  id, created_at, updated_at, phone, email, full_name, name, age, gender, dob, photo_url,
  father_tharavadu, mother_tharavadu, father_clan_id, mother_clan_id, district, state,
  about_me, education_level, occupation, income, registration_status, status, approval_status,
  account_status, subscription_tier, is_dummy, photo_approved, is_banned, is_agent, is_out_of_caste, report_count,
  house_name, blood_group, height_cm, weight_kg, taluk, post_office, pincode, family_details, hobbies
) VALUES (
  'd48908f2-09a6-4ed9-83f5-0d063881c0ef', now(), now(), '+919900020055', 'dummy_girl_56@auth.kurichiyar.com', 'സുമ ഓലിക്കൽ', 'സുമ ഓലിക്കൽ', 20, 'female', '2005-10-04', 'https://noidreeslytswkmsnmcn.supabase.co/storage/v1/object/public/user_documents/profile_photos/placeholder_female.png',
  'കർക്കോടൻ തലക്കര (കർക്കേറ്റിൽ)', 'കുണ്ടര (കുണ്ടര മൂല)', 32, 11, 'വയനാട്', 'Kerala',
  'തയ്യൽ ജോലി ചെയ്യുന്നു. ലളിതമായ സ്വഭാവമുള്ള, നല്ലൊരു ജോലി ഉള്ള ഒരാളെ വിവാഹത്തിന് ആഗ്രഹിക്കുന്നു.', 'എം.എ. ബിരുദം', 'അധ്യാപകൻ', '2 ലക്ഷം രൂപ', 'live', 'APPROVED', 'Approved',
  'adminReview', 'Free', true, true, false, false, false, 0,
  'ഓലിക്കൽ', 'A+', 165, 64, 'സുൽത്താൻ ബത്തേരി', 'മീനങ്ങാടി', '673274', 'മാതാവും പിതാവും ഒരു സഹോദരിയും അടങ്ങുന്ന സന്തുഷ്ട കുടുംബം.', '["വായിക്കുക", "തയ്യൽ", "പാചകം"]'
);
INSERT INTO public.kurichiyar_profiles (
  id, created_at, updated_at, phone, email, full_name, name, age, gender, dob, photo_url,
  father_tharavadu, mother_tharavadu, father_clan_id, mother_clan_id, district, state,
  about_me, education_level, occupation, income, registration_status, status, approval_status,
  account_status, subscription_tier, is_dummy, photo_approved, is_banned, is_agent, is_out_of_caste, report_count,
  house_name, blood_group, height_cm, weight_kg, taluk, post_office, pincode, family_details, hobbies
) VALUES (
  '37cfb1f5-4d8b-405b-ba48-28bbc7c0f329', now(), now(), '+919900020056', 'dummy_girl_57@auth.kurichiyar.com', 'ഷീന തെക്കേവീട്', 'ഷീന തെക്കേവീട്', 25, 'female', '2001-05-10', 'https://noidreeslytswkmsnmcn.supabase.co/storage/v1/object/public/user_documents/profile_photos/placeholder_female.png',
  'പരക്കടൻ (വെള്ളോട്ട്)', 'വെണ്ണിയോറ (വെണ്ണിയോറ)', 48, 23, 'കണ്ണൂർ', 'Kerala',
  'തയ്യൽ ജോലി ചെയ്യുന്നു. ലളിതമായ സ്വഭാവമുള്ള, നല്ലൊരു ജോലി ഉള്ള ഒരാളെ വിവാഹത്തിന് ആഗ്രഹിക്കുന്നു.', 'പ്ലസ് ടു', 'സ്വകാര്യ കമ്പനി ജോലി', '4 ലക്ഷം രൂപ', 'live', 'APPROVED', 'Approved',
  'adminReview', 'Free', true, true, false, false, false, 0,
  'തെക്കേവീട്', 'AB+', 157, 46, 'തലശ്ശേരി', 'മട്ടന്നൂർ', '673934', 'മാതാവും പിതാവും ഒരു സഹോദരിയും അടങ്ങുന്ന സന്തുഷ്ട കുടുംബം.', '["വായിക്കുക", "തയ്യൽ", "പാചകം"]'
);