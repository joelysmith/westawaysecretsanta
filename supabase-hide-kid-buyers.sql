-- Stops the database sending WHO bought each kids' gift (optional but recommended).
-- Run in Supabase > SQL Editor > New query > Run. Safe to run more than once.
create or replace function get_kids(p_name text, p_pin text)
returns json
language plpgsql security definer
set search_path = public
as $$
declare v text := _viewer(p_name, p_pin);
begin
  return json_build_object(
    'is_parent', (v = 'Parents'),
    'kids', (
      select coalesce(json_agg(json_build_object(
        'id', k.id,
        'name', k.name,
        'items', (
          select coalesce(json_agg(json_build_object(
            'id', i.id, 'title', i.title, 'note', i.note,
            'bought', (i.bought_by is not null),
            'bought_by_me', coalesce(i.bought_by = v, false))
            order by i.created_at, i.id), '[]'::json)
          from kid_items i where i.kid_id = k.id)
      ) order by k.created_at, k.id), '[]'::json)
      from kids k)
  );
end $$;
