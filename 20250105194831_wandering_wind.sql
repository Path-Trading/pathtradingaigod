/*
  # Trading Platform Schema Setup

  1. New Tables
    - trading_strategies
      - Stores trader's personal strategies and preferences
    - trading_agents
      - AI agents configured for each trader
    - social_signals
      - Captured trading signals from social media
    - trade_history
      - Historical trades executed by AI agents
    - performance_metrics
      - Trading performance tracking

  2. Security
    - RLS enabled on all tables
    - Policies for user data protection

  3. Relationships
    - Each user can have multiple strategies
    - Each strategy can have multiple agents
*/

-- Trading Strategies Table
CREATE TABLE IF NOT EXISTS trading_strategies (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id) NOT NULL,
  name text NOT NULL,
  description text,
  risk_tolerance decimal NOT NULL,
  max_position_size decimal NOT NULL,
  stop_loss_percentage decimal,
  take_profit_percentage decimal,
  preferred_markets text[],
  trading_timeframes text[],
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Trading Agents Table
CREATE TABLE IF NOT EXISTS trading_agents (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  strategy_id uuid REFERENCES trading_strategies(id) NOT NULL,
  name text NOT NULL,
  status text NOT NULL,
  last_active_at timestamptz,
  performance_score decimal DEFAULT 0,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Social Signals Table
CREATE TABLE IF NOT EXISTS social_signals (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  agent_id uuid REFERENCES trading_agents(id) NOT NULL,
  platform text NOT NULL,
  content text NOT NULL,
  sentiment_score decimal,
  confidence_score decimal,
  processed boolean DEFAULT false,
  created_at timestamptz DEFAULT now()
);

-- Trade History Table
CREATE TABLE IF NOT EXISTS trade_history (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  agent_id uuid REFERENCES trading_agents(id) NOT NULL,
  signal_id uuid REFERENCES social_signals(id),
  market text NOT NULL,
  position_type text NOT NULL,
  entry_price decimal NOT NULL,
  exit_price decimal,
  position_size decimal NOT NULL,
  pnl decimal,
  status text NOT NULL,
  created_at timestamptz DEFAULT now(),
  closed_at timestamptz
);

-- Performance Metrics Table
CREATE TABLE IF NOT EXISTS performance_metrics (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  agent_id uuid REFERENCES trading_agents(id) NOT NULL,
  total_trades integer DEFAULT 0,
  winning_trades integer DEFAULT 0,
  total_pnl decimal DEFAULT 0,
  win_rate decimal DEFAULT 0,
  sharpe_ratio decimal,
  max_drawdown decimal,
  period_start timestamptz NOT NULL,
  period_end timestamptz NOT NULL,
  created_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE trading_strategies ENABLE ROW LEVEL SECURITY;
ALTER TABLE trading_agents ENABLE ROW LEVEL SECURITY;
ALTER TABLE social_signals ENABLE ROW LEVEL SECURITY;
ALTER TABLE trade_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE performance_metrics ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Users can manage their own strategies"
  ON trading_strategies
  FOR ALL
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can manage their agents through strategies"
  ON trading_agents
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM trading_strategies
      WHERE trading_strategies.id = trading_agents.strategy_id
      AND trading_strategies.user_id = auth.uid()
    )
  );