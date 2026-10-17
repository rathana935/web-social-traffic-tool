# Trend Traffic Exchange — free starter website

This starter includes:
- Email/password sign-up and sign-in (Supabase Auth)
- New accounts receive 20 starter credits
- Website, Facebook, and YouTube campaign listings
- Members can submit a campaign for 20 credits
- Members can complete another member's campaign once for 1 credit
- Admin-only campaign deactivation function
- Responsive, no-framework frontend

## Important limitations
This is an MVP starter, not a production-hardened exchange. Task completion is self-confirmed in this first version; it cannot prove a human genuinely read a page. Add rate limits, abuse monitoring, moderation, email verification, privacy/terms pages, and a proper task-verification design before inviting the public. Do not use this system to generate ad clicks or ad impressions. Google AdSense prohibits invalid traffic; incentivized traffic can put monetization at risk. Avoid campaigns asking users to fake likes, follows, subscriptions, or comments.

## Setup (no local coding tools needed)

### 1) Create a free Supabase project
1. Go to https://supabase.com and create an account/project.
2. In your project dashboard, open **SQL Editor** → **New query**.
3. Open `schema.sql` from this download, copy all its contents into the SQL Editor, and click **Run**.
4. Go to **Project Settings → API** (sometimes shown as **Data API / API Keys**).
5. Copy the **Project URL** and the **publishable/anon key**. Never use or publish the `service_role` / secret key.

### 2) Add the project details
1. Open `index.html` in a text editor (Notepad is fine).
2. Find:
   `const SUPABASE_URL = "YOUR_SUPABASE_PROJECT_URL";`
   and replace the placeholder with your Project URL.
3. Find:
   `const SUPABASE_ANON_KEY = "YOUR_SUPABASE_ANON_KEY";`
   and replace the placeholder with the publishable/anon key.
4. Save the file. Keep the quotes around both values.

### 3) Publish for free with Netlify
1. Go to https://app.netlify.com and create a free account.
2. In this ZIP, the website file is `index.html`. Extract the ZIP on your computer.
3. Drag the extracted folder containing `index.html` to Netlify's manual deploy area (Netlify Drop / Add new site → Deploy manually).
4. Netlify will provide a public URL.

### 4) Configure Supabase authentication
1. In Supabase, open **Authentication → URL Configuration**.
2. Set **Site URL** to the Netlify URL.
3. Add the Netlify URL to **Redirect URLs** (e.g. `https://your-site-name.netlify.app/**`).
4. Under **Authentication → Providers → Email**, decide whether to require email confirmation. Recommended: leave confirmation enabled.
5. Test creating a user, confirming email if required, and signing in.

### 5) Make your account an admin
1. Sign up on your published website.
2. In Supabase, open **Authentication → Users**, find your account and copy its User UID.
3. Open **SQL Editor** and run the following command after replacing `YOUR-USER-UUID` with your UID:
   `update public.profiles set is_admin = true where id = 'YOUR-USER-UUID';`
4. Sign out and sign back in. The Admin tab should appear.

## How the credit rules work
- New account: 20 starter credits.
- Submit a campaign: 20 credits.
- Complete another user's campaign: 1 credit once per campaign per user.
- Credits are changed by database functions, not by editable browser fields.

## Before launching publicly
- Add Terms, Privacy Policy, contact information, report-abuse process, and clear rules.
- Set a maximum number of campaigns per user and implement moderation.
- The current MVP only checks that a user clicks confirmation after opening a URL; it does not verify visit duration or actual engagement.
- If you plan to earn from AdSense, do not send exchange traffic to pages for the purpose of generating ad impressions/clicks.
