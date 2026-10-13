-- Setlist Maker: database setup for Supabase.
-- Paste this whole file into Supabase > SQL Editor > New query and press Run.
-- Safe to run again.

-- Logins that may read and edit the setlists (the shared band login).
create table if not exists public.band_members (
  email text primary key
);

create table if not exists public.gigs (
  id text primary key,
  venue text not null default '',
  date text not null default '',
  songs jsonb not null default '[]'::jsonb,
  updated_at timestamptz not null default now()
);

create table if not exists public.library (
  id text primary key,
  title text not null,
  note text not null default ''
);

-- One row, id = 'band': band name, sheet options and the logo (data URL).
create table if not exists public.settings (
  id text primary key,
  band text not null default '',
  numbered boolean not null default true,
  caps boolean not null default true,
  notes boolean not null default true,
  logo text
);

create or replace function public.is_band_member()
returns boolean
language sql stable security definer
set search_path = public
as $$
  select exists (
    select 1 from public.band_members
    where lower(email) = lower(coalesce(auth.jwt() ->> 'email', ''))
  );
$$;

create or replace function public.touch_updated_at()
returns trigger language plpgsql as $$
begin new.updated_at = now(); return new; end;
$$;
drop trigger if exists gigs_touch on public.gigs;
create trigger gigs_touch before update on public.gigs
  for each row execute function public.touch_updated_at();

alter table public.band_members enable row level security;
alter table public.gigs         enable row level security;
alter table public.library      enable row level security;
alter table public.settings     enable row level security;

drop policy if exists "members see the band list" on public.band_members;
create policy "members see the band list" on public.band_members
  for select to authenticated using (public.is_band_member());

drop policy if exists "members use gigs" on public.gigs;
create policy "members use gigs" on public.gigs
  for all to authenticated using (public.is_band_member()) with check (public.is_band_member());

drop policy if exists "members use library" on public.library;
create policy "members use library" on public.library
  for all to authenticated using (public.is_band_member()) with check (public.is_band_member());

drop policy if exists "members use settings" on public.settings;
create policy "members use settings" on public.settings
  for all to authenticated using (public.is_band_member()) with check (public.is_band_member());

-- Live updates.
do $$
begin
  begin alter publication supabase_realtime add table public.gigs;     exception when duplicate_object then null; end;
  begin alter publication supabase_realtime add table public.library;  exception when duplicate_object then null; end;
  begin alter publication supabase_realtime add table public.settings; exception when duplicate_object then null; end;
end $$;

-- The shared band login. Create a user with this same email under
-- Authentication > Users > Add user (tick "Auto Confirm User"); its password
-- is the band password. It must match SUPABASE_BAND_EMAIL in src/setlist.html.
insert into public.band_members (email) values
  ('band@setlist-maker.app')
on conflict do nothing;
