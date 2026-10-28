-- Whether easiYESt may share a vendor's listing photos on its social media,
-- with credit to the business. The listing forms (website and app) show the
-- box checked by default. Null means the vendor hasn't seen the question yet
-- (listings saved before it existed), which is not a yes.

alter table public.vendors add column if not exists allow_social_photos boolean;

comment on column public.vendors.allow_social_photos is
  'Vendor agreed their photos can appear on easiYESt social media with credit. Null = not asked yet.';
