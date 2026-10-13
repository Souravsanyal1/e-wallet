-- EliteChat Seed Data for local development
-- Insert default plans
insert into public.plans (slug, title, description, price_amount, price_token, duration_days, is_active)
values
  ('pro', 'Pro Trader', 'Unlock token-gated alpha channels, custom profile badge, and uncompressed media uploads.', 50000000, 'USDC', 30, true),
  ('whale', 'Alpha Insider', 'Direct channel broadcast rights, priority DM delivery, and exclusive analytics bot access.', 150000000, 'USDC', 30, true)
on conflict (slug) do nothing;
