-- ============================================================
-- easiYESt - Supabase Migrations
-- Run these in the Supabase SQL Editor in order
-- ============================================================

-- ==================== WEDDING PROFILES ====================
CREATE TABLE IF NOT EXISTS wedding_profiles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
  wedding_date DATE,
  partner_name_1 TEXT NOT NULL DEFAULT '',
  partner_name_2 TEXT NOT NULL DEFAULT '',
  wedding_location TEXT NOT NULL DEFAULT '',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE wedding_profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage their own wedding profile"
  ON wedding_profiles
  FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- ==================== CHECKLIST TEMPLATES ====================
CREATE TABLE IF NOT EXISTS checklist_templates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  description TEXT DEFAULT '',
  category TEXT NOT NULL DEFAULT 'Other',
  months_before INT NOT NULL DEFAULT 0,
  display_order INT NOT NULL DEFAULT 0
);

-- No RLS needed - templates are public read-only
ALTER TABLE checklist_templates ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Anyone can read checklist templates"
  ON checklist_templates
  FOR SELECT
  USING (true);

-- ==================== USER CHECKLIST ITEMS ====================
CREATE TABLE IF NOT EXISTS user_checklist_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  template_id UUID REFERENCES checklist_templates(id),
  title TEXT NOT NULL,
  description TEXT DEFAULT '',
  category TEXT NOT NULL DEFAULT 'Other',
  is_completed BOOLEAN NOT NULL DEFAULT false,
  due_date DATE,
  display_order INT NOT NULL DEFAULT 0,
  notes TEXT DEFAULT '',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE user_checklist_items ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage their own checklist"
  ON user_checklist_items
  FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- ==================== USER BUDGETS ====================
CREATE TABLE IF NOT EXISTS user_budgets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
  total_budget NUMERIC(12, 2) NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE user_budgets ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage their own budget"
  ON user_budgets
  FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- ==================== BUDGET ITEMS ====================
CREATE TABLE IF NOT EXISTS budget_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  category TEXT NOT NULL DEFAULT 'Other',
  item_name TEXT NOT NULL,
  vendor_id UUID REFERENCES vendors(vendor_id),
  estimated_cost NUMERIC(12, 2) NOT NULL DEFAULT 0,
  actual_cost NUMERIC(12, 2),
  is_paid BOOLEAN NOT NULL DEFAULT false,
  notes TEXT DEFAULT '',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE budget_items ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage their own budget items"
  ON budget_items
  FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- ==================== GUESTS ====================
CREATE TABLE IF NOT EXISTS guests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  first_name TEXT NOT NULL,
  last_name TEXT NOT NULL DEFAULT '',
  email TEXT DEFAULT '',
  phone TEXT DEFAULT '',
  group_name TEXT NOT NULL DEFAULT '',
  rsvp_status TEXT NOT NULL DEFAULT 'not_sent'
    CHECK (rsvp_status IN ('not_sent', 'invited', 'accepted', 'declined', 'maybe')),
  meal_preference TEXT DEFAULT '',
  dietary_restrictions TEXT DEFAULT '',
  plus_one_allowed BOOLEAN NOT NULL DEFAULT false,
  plus_one_name TEXT DEFAULT '',
  notes TEXT DEFAULT '',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE guests ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage their own guests"
  ON guests
  FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- ==================== CHECKLIST TEMPLATE SEED DATA ====================
-- Standard wedding checklist tasks (40 tasks across categories)
INSERT INTO checklist_templates (title, description, category, months_before, display_order) VALUES

-- 12+ months before
('Set your wedding date', 'Decide on your preferred date and have a backup', 'Planning', 14, 10),
('Set your budget', 'Determine your total wedding budget', 'Planning', 14, 20),
('Create your guest list', 'Draft your initial guest list', 'Planning', 13, 30),
('Research and book your venue', 'Visit and compare venues, book your favorite', 'Venue', 12, 40),
('Hire a wedding planner (optional)', 'Consider hiring a coordinator or day-of coordinator', 'Planning', 12, 50),
('Book your officiant', 'Find and book your ceremony officiant', 'Planning', 12, 60),
('Start engagement photos', 'Schedule engagement photo session', 'Photography', 12, 70),

-- 10-11 months before
('Book your photographer', 'Research, meet, and book a photographer', 'Photography', 11, 80),
('Book your videographer', 'Research and book a videographer if desired', 'Videography', 11, 90),
('Book your caterer', 'Research catering options and book your caterer', 'Catering', 11, 100),
('Book your band or DJ', 'Research and book entertainment', 'Music', 10, 110),
('Start dress shopping', 'Begin shopping for your wedding dress', 'Attire', 10, 120),

-- 8-9 months before
('Choose your wedding party', 'Ask your bridesmaids and groomsmen', 'Planning', 9, 130),
('Book your florist', 'Meet with florists and book your favorite', 'Flowers', 9, 140),
('Register for gifts', 'Create your wedding registry', 'Planning', 9, 150),
('Plan your honeymoon', 'Research and book honeymoon destination', 'Planning', 9, 160),
('Order wedding cake', 'Schedule tastings and order your cake', 'Catering', 8, 170),

-- 6-7 months before
('Send save-the-dates', 'Design and mail save-the-dates', 'Invitations', 7, 180),
('Book hair and makeup', 'Research and book hair and makeup artists', 'Hair & Makeup', 7, 190),
('Book transportation', 'Arrange transportation for wedding day', 'Transportation', 7, 200),
('Plan ceremony details', 'Choose readings, music, and ceremony structure', 'Planning', 6, 210),
('Book rehearsal dinner venue', 'Reserve location for rehearsal dinner', 'Venue', 6, 220),
('Groom attire shopping', 'Shop for suit or tuxedo', 'Attire', 6, 230),

-- 4-5 months before
('Order invitations', 'Design and order wedding invitations', 'Invitations', 5, 240),
('Plan decor', 'Finalize centerpieces and decorations', 'Decor', 5, 250),
('Schedule cake tasting', 'Finalize cake flavors and design', 'Catering', 5, 260),
('Book hotel room blocks', 'Reserve hotel rooms for out-of-town guests', 'Planning', 5, 270),
('Choose wedding favors', 'Select and order guest favors', 'Decor', 4, 280),
('Finalize menu', 'Confirm menu with caterer', 'Catering', 4, 290),

-- 2-3 months before
('Mail invitations', 'Send out wedding invitations', 'Invitations', 3, 300),
('Schedule fittings', 'Book final dress/suit alterations', 'Attire', 3, 310),
('Apply for marriage license', 'Research requirements and apply', 'Planning', 3, 320),
('Write vows', 'Personalize your wedding vows', 'Planning', 3, 330),
('Plan seating chart', 'Create tentative seating arrangement', 'Planning', 2, 340),
('Confirm all vendors', 'Touch base with every vendor', 'Planning', 2, 350),

-- 1 month before
('Final RSVP count', 'Collect all RSVPs and give final count to caterer', 'Planning', 1, 360),
('Create wedding day timeline', 'Build a detailed schedule for the day', 'Planning', 1, 370),
('Prepare payments and tips', 'Prepare vendor payments and tip envelopes', 'Planning', 1, 380),
('Final dress fitting', 'Pick up your dress after final alterations', 'Attire', 1, 390),
('Rehearsal', 'Run through the ceremony with wedding party', 'Planning', 0, 400)

ON CONFLICT DO NOTHING;

-- ==================== BOOKED VENDOR STATUS ====================
ALTER TABLE user_diamonds ADD COLUMN IF NOT EXISTS is_booked BOOLEAN DEFAULT false;
ALTER TABLE vendors ADD COLUMN IF NOT EXISTS bookings_count INT DEFAULT 0;

CREATE OR REPLACE FUNCTION toggle_vendor_booking(vendor_uuid UUID, increment BOOLEAN)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  IF increment THEN
    UPDATE vendors SET bookings_count = bookings_count + 1 WHERE vendor_id = vendor_uuid;
  ELSE
    UPDATE vendors SET bookings_count = GREATEST(0, bookings_count - 1) WHERE vendor_id = vendor_uuid;
  END IF;
END;
$$;
