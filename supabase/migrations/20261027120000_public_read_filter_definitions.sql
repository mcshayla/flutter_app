-- Filter definitions (names, labels, icons) are public catalog data, like
-- categories. The website's vendor pages are built without a login, so
-- anonymous visitors need to read them too.
create policy "Anyone can read category filters" on public.category_filters for select to anon using (true);
create policy "Anyone can read filter options" on public.filter_options for select to anon using (true);
