-- "Invitations " had a trailing space, so checklist templates filed under
-- "Invitations" never matched and the app skipped those tasks. Nothing else
-- references the padded name (checked 2026-10-27); category_filters follows
-- by ON UPDATE CASCADE.
update public.categories set name = btrim(name) where name <> btrim(name);
