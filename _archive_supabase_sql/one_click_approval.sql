-- FUNCTION TO APPROVE A USER PROFILE INSTANTLY
create or replace function APPROVE_USER_PROFILE(TARGET_USER_ID uuid)
returns VOID as $$
begin
    update KURICHIYAR_PROFILES
    set 
        ACCOUNT_STATUS = 'active',
        REGISTRATION_STATUS = 'approved',
        IS_VERIFIED = true,
        APP_SCREEN_OVERRIDE = 'main_screen',
        VERIFICATION_OTP = null -- CLEAR otp SINCE IT'S NO LONGER REQUIRED
    where ID = TARGET_USER_ID;
end;
$$ language PLPGSQL security definer;     

-- TRIGGER TO SEND NOTIFICATION WHEN USER GETS APPROVED    
create or replace function NOTIFY_USER_ON_APPROVAL()    
returns TRIGGER as $$
begin
  if (new.ACCOUNT_STATUS = 'active' and (old.ACCOUNT_STATUS is null or old.ACCOUNT_STATUS != 'active')) then
    perform NET.HTTP_POST(
      URL := 'HTTPS://<YOUR-SUPABASE-PROJECT>.SUPABASE.CO/FUNCTIONS/V1/SEND-USER-NOTIFICATION',
      HEADERS := '{"CONTENT-TYPE": "APPLICATION/JSON", "AUTHORIZATION": "BEARER <SERVICE_ROLE_KEY>"}'::JSONB,
      BODY := JSONB_BUILD_OBJECT(
        'TITLE', 'Account Approved!',
        'BODY', 'Your profile verification is complete. You can now access the Home Screen.',
        'USER_ID', new.ID,
        'FCM_TOKEN', new.FCM_TOKEN
      )
    );
  end if;
  return new;
end;
$$ language PLPGSQL security definer;

drop trigger if exists ON_USER_APPROVAL_TRIGGER on KURICHIYAR_PROFILES;

create trigger ON_USER_APPROVAL_TRIGGER
after update on KURICHIYAR_PROFILES
for each row execute function NOTIFY_USER_ON_APPROVAL();
