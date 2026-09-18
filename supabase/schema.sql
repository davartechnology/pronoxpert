-- Schema PronoXpert — a coller dans Supabase Dashboard > SQL Editor > New query > Run

create table if not exists categories (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  icon text default '⚽',
  order_index int not null default 0,
  -- tier utilise par l'automatisation : 'free' (2 cotes les plus basses) ou 'reward_ad' (2 cotes les plus hautes)
  tier text not null default 'free' check (tier in ('free', 'reward_ad')),
  odds numeric,
  created_at timestamptz not null default now()
);

create table if not exists matches (
  id uuid primary key default gen_random_uuid(),
  category_id uuid not null references categories(id) on delete cascade,
  championship text not null,
  country text not null,
  match_time timestamptz not null,
  team1 text not null,
  team2 text not null,
  option_chosen text not null,
  odds numeric not null,
  justification text,
  is_visible boolean not null default true,
  result text not null default 'pending' check (result in ('pending', 'won', 'lost')),
  result_date date,
  created_at timestamptz not null default now()
);

create table if not exists ads (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  content text,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

-- Lecture publique (les utilisateurs de l'app ne se connectent pas)
alter table categories enable row level security;
alter table matches enable row level security;
alter table ads enable row level security;

create policy "public read categories" on categories for select using (true);
create policy "public read visible matches" on matches for select using (is_visible = true);
create policy "public read active ads" on ads for select using (is_active = true);

-- Categories fixes : 1 a 4 tickets, l'automatisation remplit celle(s) qui ont des matchs ce jour-la
insert into categories (name, icon, order_index, tier) values
  ('Ticket 1', '🎯', 1, 'free'),
  ('Ticket 2', '🎯', 2, 'free'),
  ('Ticket 3', '🔥', 3, 'reward_ad'),
  ('Ticket 4', '🔥', 4, 'reward_ad')
on conflict do nothing;
