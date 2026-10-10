# Reuben Ngui Portfolio

Static site (Vercel) + Supabase (database, login, photo storage) + one Vercel function (`api/contact.js`) for the contact form.

## Files
index.html (website) · admin/index.html (admin panel) · api/contact.js · site.css · config.js · vercel.json · robots.txt · schema.sql · images/ (your starter photos)

## Setup
1. Create a NEW Supabase project (free) for this site.
2. Authentication > Sign In / Providers: turn OFF "Allow new users to sign up".
3. SQL Editor: paste all of schema.sql and Run. It creates the tables, security rules, photo storage and loads your starter photos.
4. Authentication > Users > Add user (email + password, tick Auto Confirm). The first user becomes the ONLY administrator.
5. Authentication > URL Configuration: Site URL = your Vercel address; add https://YOUR-SITE.vercel.app/admin/ to Redirect URLs.
6. config.js: paste the new project's URL and publishable key (Project Settings > API).
7. Push to GitHub, import the repo in Vercel (Framework Preset: Other).
8. Contact form email (Vercel > Settings > Environment Variables): RESEND_API_KEY and CONTACT_TO_EMAIL (see .env.example). Redeploy.
9. Log in at /admin/login > Contact Settings: add your WhatsApp number and email. Social Media Settings: add your profile links.

## What the admin panel can edit (everything on the website)
Photos & memories · Story chapters · Interests and the 4 highlight cards · Categories · About, hero, quick facts, footer and website description ·
hero portrait and background photo · Contact email and WhatsApp number · Social links · Site Text & Labels (every menu name, heading, button and message) ·
Appearance & Sections (two brand colours, and switches to show or hide each section) · Password.
After saving, refresh the website to see the change.

## Tests
Log in; upload a photo (published) and see it in the gallery; edit its caption and refresh; open the site on another phone;
draft photos stay hidden; search and category filters; lightbox arrows; WhatsApp/email buttons; contact form; delete a photo.
