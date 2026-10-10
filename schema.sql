-- =====================================================================
-- REUBEN NGUI PORTFOLIO: run once in Supabase > SQL Editor.
-- Safe to re-run. Best used in its OWN Supabase project (a free account allows two).
-- =====================================================================

-- ---------- one administrator only ----------
create table if not exists portfolio_admin (
  singleton boolean primary key default true check (singleton),
  user_id   uuid not null unique references auth.users(id) on delete cascade
);
alter table portfolio_admin enable row level security;

create or replace function is_portfolio_admin() returns boolean
language sql stable security definer set search_path = public as
$$ select exists (select 1 from portfolio_admin where user_id = auth.uid()) $$;

create or replace function portfolio_new_user() returns trigger
language plpgsql security definer set search_path = public as $$
begin insert into portfolio_admin (user_id) values (new.id) on conflict do nothing; return new; end $$;

drop trigger if exists on_auth_user_created_portfolio on auth.users;
create trigger on_auth_user_created_portfolio after insert on auth.users
  for each row execute function portfolio_new_user();
-- if a user already exists, the oldest one becomes the administrator
insert into portfolio_admin (user_id) select id from auth.users order by created_at limit 1 on conflict do nothing;

-- ---------- tables ----------
create table if not exists profiles (
  id int primary key default 1 check (id = 1),
  full_name text not null default 'Reuben Ngui',
  tagline text default 'Just Reuben. Nothing complicated.',
  hero_intro text default 'I’m a young man with big dreams, a curious mind and a heart that values real connections. I love good conversations, great people, new experiences and making the most of life.',
  location_label text default 'Based in Kenya',
  born_info text,                                   -- hidden on the site until you fill it in
  lifestyle text default 'Grateful · Focused · Growing',
  hero_quote text default 'Good things take time.',
  about_text text default 'Reuben is a person who believes in living fully, appreciating genuine connections, learning from every chapter of life, and creating memories worth keeping. He enjoys good conversations, meaningful friendships, travel, football, music, and anything that brings peace and happiness.',
  about_long text,
  location text default 'Nairobi, Kenya',
  education text default 'Degree in Actuarial Science (Graduate)',
  occupation text default 'Accounts & Finance Officer (2+ years experience)',
  personal_motto text default 'Turn dreams into plans.',
  story_intro text default 'Every chapter of my life has shaped who I am today. From the challenges to the wins, I’ve learned, grown and found strength in unexpected places. I’m still writing my story, and the best parts are yet to come.',
  footer_text text default 'Life is better when you’re surrounded by good people, great moments and big dreams.',
  footer_quote text default 'Same guy. Bigger dreams.',
  contact_email text,
  whatsapp_number text,                             -- international format, e.g. 2547XXXXXXXX
  hero_image_url text,
  background_image_url text,
  meta_description text default 'Personal website of Reuben Ngui: photos, story, interests and ways to connect.',
  updated_at timestamptz not null default now()
);
insert into profiles (id) values (1) on conflict do nothing;

create table if not exists categories (
  id bigint generated always as identity primary key,
  name text not null unique, description text, display_order int not null default 0
);
insert into categories (name, description, display_order) values
  ('Just Me','Same guy, different day.',1), ('Graduation Day','A big chapter closed.',2),
  ('Travel Moments','Collecting memories.',3), ('Football Vibes','More than just a game.',4),
  ('Good Company','Real ones. Always.',5), ('Sunsets & Reflections','Peace looks good on me.',6),
  ('Lifestyle','Work hard, enjoy more.',7), ('Exploring','New places. Same dream.',8)
on conflict (name) do nothing;

create table if not exists photos (
  id bigint generated always as identity primary key,
  title text not null check (length(trim(title)) between 1 and 120),
  caption text check (length(caption) <= 200),
  memory text check (length(memory) <= 5000),
  image_url text not null, thumbnail_url text,
  photo_date date, location text check (length(location) <= 120),
  category_id bigint references categories(id) on delete set null,
  alt_text text check (length(alt_text) <= 200),
  is_featured boolean not null default false,
  status text not null default 'draft' check (status in ('draft','published')),
  display_order int not null default 0,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create index if not exists photos_pub_idx on photos (status, photo_date desc);

create table if not exists story_chapters (
  id bigint generated always as identity primary key,
  title text not null check (length(trim(title)) between 1 and 120),
  content text check (length(content) <= 20000),
  chapter_date date, cover_image_url text,
  display_order int not null default 0,
  status text not null default 'draft' check (status in ('draft','published')),
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
-- chapters start as drafts with NO text: nothing is invented, write them in the admin panel
insert into story_chapters (title, display_order)
select t, o from (values ('My Beginnings',1),('Education and Growth',2),('Career and Professional Development',3),
  ('People and Relationships',4),('Travel and Adventures',5),('Lessons Learned',6),('My Future Aspirations',7)) v(t,o)
where not exists (select 1 from story_chapters);

create table if not exists interests (
  id bigint generated always as identity primary key,
  title text not null check (length(trim(title)) between 1 and 80),
  card_title text, tagline text, description text check (length(description) <= 3000),
  icon text not null default 'fa-heart', image_url text,
  display_order int not null default 0,
  status text not null default 'published' check (status in ('draft','published')),
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
insert into interests (title, card_title, tagline, icon, display_order)
select * from (values
  ('Travel','Love Traveling','New places, new stories.','fa-plane',1),
  ('Football','Football Fan','The beautiful game.','fa-futbol',2),
  ('Music','Music Lover','Good vibes, all day.','fa-music',3),
  ('Learning and Personal Growth','Lifelong Learner','Always curious.','fa-book-open',4),
  ('Nature',null,null,'fa-leaf',5), ('Good Food',null,null,'fa-utensils',6),
  ('Friends',null,null,'fa-user-group',7), ('Family',null,null,'fa-people-roof',8), ('Peace',null,null,'fa-dove',9)
) v(a,b,c,d,e) where not exists (select 1 from interests);

create table if not exists social_links (
  id bigint generated always as identity primary key,
  platform text not null unique, profile_url text, display_order int not null default 0, is_enabled boolean not null default false
);
insert into social_links (platform, display_order) values
  ('instagram',1),('tiktok',2),('facebook',3),('x',4),('linkedin',5) on conflict (platform) do nothing;
-- WhatsApp uses the number in profiles.whatsapp_number

-- every editable piece of website text, colour and section switch (managed in the admin panel)
create table if not exists site_settings (
  key text primary key, value text, updated_at timestamptz not null default now()
);

-- ---------- timestamps ----------
create or replace function touch_updated_at() returns trigger language plpgsql as
$$ begin new.updated_at = now(); return new; end $$;
do $$ declare t text; begin
  foreach t in array array['profiles','photos','story_chapters','interests','site_settings'] loop
    execute format('drop trigger if exists touch on %I', t);
    execute format('create trigger touch before update on %I for each row execute function touch_updated_at()', t);
  end loop; end $$;

-- ---------- Row Level Security ----------
do $$ declare t text; begin
  foreach t in array array['profiles','categories','photos','story_chapters','interests','social_links','site_settings'] loop
    execute format('alter table %I enable row level security', t);
    execute format('drop policy if exists "admin all" on %I', t);
    execute format('create policy "admin all" on %I for all to authenticated using (is_portfolio_admin()) with check (is_portfolio_admin())', t);
    execute format('drop policy if exists "public read" on %I', t);
  end loop; end $$;

-- the public can read ONLY published content
create policy "public read" on profiles       for select to anon, authenticated using (true);
create policy "public read" on categories     for select to anon, authenticated using (true);
create policy "public read" on photos         for select to anon, authenticated using (status = 'published');
create policy "public read" on story_chapters for select to anon, authenticated using (status = 'published');
create policy "public read" on interests      for select to anon, authenticated using (status = 'published');
create policy "public read" on site_settings   for select to anon, authenticated using (true);
create policy "public read" on social_links   for select to anon, authenticated using (is_enabled and coalesce(profile_url,'') <> '');

-- ---------- image storage ----------
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('portfolio', 'portfolio', true, 8388608, array['image/jpeg','image/png','image/webp'])
on conflict (id) do update set public = true, file_size_limit = 8388608, allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "portfolio public read" on storage.objects;
drop policy if exists "portfolio admin write" on storage.objects;
create policy "portfolio public read" on storage.objects for select using (bucket_id = 'portfolio');
create policy "portfolio admin write" on storage.objects for all to authenticated
  using (bucket_id = 'portfolio' and is_portfolio_admin()) with check (bucket_id = 'portfolio' and is_portfolio_admin());

-- ---------- permissions ----------
grant usage on schema public to anon, authenticated;
grant select on profiles, categories, photos, story_chapters, interests, social_links, site_settings to anon;
grant all on profiles, categories, photos, story_chapters, interests, social_links, site_settings to authenticated;
grant usage, select on all sequences in schema public to authenticated;
revoke all on function is_portfolio_admin() from public;
grant execute on function is_portfolio_admin() to authenticated;
notify pgrst, 'reload schema';

-- ---------- starter photos (your sample images, served from /images) ----------
-- Runs only while no starter photos exist. Edit or delete them later in the admin panel,
-- and add the rest of your photos there too.
insert into photos (title, caption, image_url, thumbnail_url, category_id, alt_text, is_featured, status, display_order)
select v.title, v.caption, '/images/photo-' || v.n || '.jpg', '/images/thumb-' || v.n || '.jpg',
       (select id from categories where name = v.cat), v.alt, v.feat, 'published', v.n
from (values
  (1,'Just Me','Same guy, different day.','Just Me','Reuben in a black polo beside a green palm leaf',true),
  (2,'Graduation Day','A big chapter closed.','Graduation Day','Reuben in a black graduation cap and gown with a red and gold sash',true),
  (3,'Travel Moments','Collecting memories.','Travel Moments','Reuben standing on a rocky ledge above a wide green valley, hand on his sunglasses',true),
  (4,'Football Vibes','More than just a game.','Football Vibes','Reuben in a sky-blue football shirt with a sunset city skyline behind him',true),
  (5,'Good Company','Real ones. Always.','Good Company','Reuben with a friend on a rocky hilltop overlooking a town',true),
  (6,'Sunsets & Reflections','Peace looks good on me.','Sunsets & Reflections','The sun setting over a calm lake with a splash of water',true),
  (7,'Lifestyle','Work hard, enjoy more.','Lifestyle','Reuben in a black T-shirt and jeans standing on a quiet tree-lined road',true),
  (8,'Exploring','New places. Same dream.','Exploring','Reuben walking on a green lawn in front of old stone buildings',true),
  (9,'On the Ridge','Collecting memories.','Travel Moments','Reuben in a peach hoodie standing on rocks above a green valley',false),
  (10,'Friends at the Doorway','Real ones. Always.','Good Company','Reuben and a friend in front of an old stone arched doorway',false),
  (11,'Sunny Day','Same guy, different day.','Just Me','Reuben in a white T-shirt with his arms crossed, outdoors',false),
  (12,'Night Frame','Work hard, enjoy more.','Lifestyle','Reuben in a black T-shirt with arms crossed in front of a white lattice gate at night',false),
  (13,'Afternoon Walk','Work hard, enjoy more.','Lifestyle','Reuben in a white graphic T-shirt walking along a paved path',false),
  (14,'In Blue','Work hard, enjoy more.','Lifestyle','Reuben in a blue T-shirt and dark jeans standing in front of a dark doorway',false)
) v(n, title, caption, cat, alt, feat)
where not exists (select 1 from photos where image_url like '/images/%');

-- starter hero images (replace them any time in Edit About & Site Content)
update profiles set hero_image_url = '/images/hero-portrait.jpg', background_image_url = '/images/hero-bg.jpg'
where id = 1 and hero_image_url is null and background_image_url is null;
