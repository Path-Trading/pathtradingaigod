import * as tf from '@tensorflow/tfjs';

export class SentimentAnalyzer {
  private model: tf.LayersModel | null = null;
  private readonly vocabSize = 10000;
  private readonly maxLength = 100;

  async initialize() {
    this.model = tf.sequential({
      layers: [
        tf.layers.embedding({
          inputDim: this.vocabSize,
          outputDim: 16,
          inputLength: this.maxLength
        }),
        tf.layers.globalAveragePooling1d({}),
        tf.layers.dense({ units: 16, activation: 'relu' }),
        tf.layers.dense({ units: 1, activation: 'sigmoid' })
      ]
    });

    this.model.compile({
      optimizer: tf.train.adam(0.001),
      loss: 'binaryCrossentropy',
      metrics: ['accuracy']
    });
  }

  async analyzeSentiment(text: string): Promise<number> {
    if (!this.model) {
      throw new Error('Model not initialized');
    }
    
    // Simple sentiment score for demo purposes
    const words = text.toLowerCase().split(' ');
    const positiveWords = ['good', 'great', 'awesome', 'excellent', 'happy'];
    const negativeWords = ['bad', 'terrible', 'awful', 'sad', 'angry'];
    
    let score = 0.5;
    words.forEach(word => {
      if (positiveWords.includes(word)) score += 0.1;
      if (negativeWords.includes(word)) score -= 0.1;
    });
    
    return Math.max(0, Math.min(1, score));
  }
}