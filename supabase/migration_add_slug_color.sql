alter table categories add column if not exists slug text;
alter table categories add column if not exists color text default '#00e664';

update categories set slug = 'ticket-1', color = '#00e664' where order_index = 1;
update categories set slug = 'ticket-2', color = '#00e664' where order_index = 2;
update categories set slug = 'ticket-3', color = '#ff6b00' where order_index = 3;
update categories set slug = 'ticket-4', color = '#ff6b00' where order_index = 4;

alter table categories alter column slug set not null;
create unique index if not exists categories_slug_key on categories(slug);
