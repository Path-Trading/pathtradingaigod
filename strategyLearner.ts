import * as tf from '@tensorflow/tfjs';
import type { TradeHistory } from '../../types';

export class StrategyLearner {
  private model: tf.LayersModel | null = null;

  async initialize() {
    this.model = tf.sequential({
      layers: [
        tf.layers.lstm({
          units: 50,
          returnSequences: true,
          inputShape: [null, 5]
        }),
        tf.layers.dropout({ rate: 0.2 }),
        tf.layers.lstm({ units: 50 }),
        tf.layers.dense({ units: 3, activation: 'softmax' })
      ]
    });

    this.model.compile({
      optimizer: tf.train.adam(0.001),
      loss: 'categoricalCrossentropy',
      metrics: ['accuracy']
    });
  }

  async learnFromHistory(tradeHistory: TradeHistory[]) {
    if (!this.model) throw new Error('Model not initialized');

    const features = this.preprocessTradeHistory(tradeHistory);
    const labels = this.generateLabels(tradeHistory);

    await this.model.fit(features, labels, {
      epochs: 100,
      batchSize: 32,
      validationSplit: 0.2
    });
  }

  private preprocessTradeHistory(history: TradeHistory[]) {
    // Convert trade history to tensors
    return tf.tensor3d(history.map(trade => [
      [
        trade.entry_price,
        trade.exit_price || 0,
        trade.position_size,
        trade.pnl || 0,
        trade.confidence_score
      ]
    ]));
  }

  private generateLabels(history: TradeHistory[]) {
    // Generate one-hot encoded labels for trades
    return tf.tensor2d(history.map(trade => {
      if (trade.pnl > 0) return [1, 0, 0]; // Profitable
      if (trade.pnl < 0) return [0, 1, 0]; // Loss
      return [0, 0, 1]; // Break-even
    }));
  }
}