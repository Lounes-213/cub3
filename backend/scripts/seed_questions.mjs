import fs from 'fs';
import path from 'path';

// Read questions_bank.dart and extract the questions
const filePath = path.resolve('../../lib/data/questions_bank.dart');
const content = fs.readFileSync(filePath, 'utf-8');

const regex = /QuestionModel\s*\(\s*category:\s*'([^']+)',\s*questionText:\s*'([^']+)',\s*options:\s*\[([^\]]+)\],\s*correctAnswer:\s*'([^']+)',\s*explanation:\s*'([^']+)'(?:,\s*hint1:\s*'([^']*)')?(?:,\s*hint2:\s*'([^']*)')?(?:,\s*hint3:\s*'([^']*)')?/g;

const questions = [];
let match;
let idx = 1;

while ((match = regex.exec(content)) !== null) {
  const [_, category, questionText, rawOptions, correctAnswer, explanation, hint1, hint2, hint3] = match;
  const options = rawOptions
    .split(',')
    .map(o => o.trim().replace(/^['"]|['"]$/g, ''))
    .filter(Boolean);

  questions.push({
    id: `q_${idx++}`,
    category,
    questionText,
    options,
    correctAnswer,
    explanation,
    hint1: hint1 || '',
    hint2: hint2 || '',
    hint3: hint3 || '',
  });
}

console.log(`Extracted ${questions.length} questions.`);

async function seed() {
  const res = await fetch('https://cube-iii.cube-iii-backend.workers.dev/api/questions/seed', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(questions),
  });
  const data = await res.json();
  console.log('Seed response:', data);
}

seed().catch(console.error);
