
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() => runApp(const BarPrepApp());

const navy = Color(0xFF07172E);
const navy2 = Color(0xFF102B4E);
const gold = Color(0xFFFFC857);
const green = Color(0xFF20B875);
const red = Color(0xFFE74452);
const purple = Color(0xFF7953F5);
const blue = Color(0xFF2678F5);

class MCQ {
  final int id;
  final String question;
  final List<String> options;
  final int answer;
  final String explanation;
  final String difficulty;

  const MCQ({
    required this.id,
    required this.question,
    required this.options,
    required this.answer,
    this.explanation = '',
    this.difficulty = 'simple',
  });

  factory MCQ.fromJson(Map<String, dynamic> j) => MCQ(
    id: j['id'] as int,
    question: j['question'] as String,
    options: List<String>.from(j['options']),
    answer: j['answer'] as int,
    explanation: j['explanation'] ?? '',
    difficulty: j['difficulty'] ?? 'simple',
  );
}

class BarPrepApp extends StatelessWidget {
  const BarPrepApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Biplob BAR Plan',
    theme: ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: navy,
      colorScheme: ColorScheme.fromSeed(
        seedColor: gold,
        brightness: Brightness.dark,
      ),
      fontFamily: 'Roboto',
    ),
    home: const HomeScreen(),
  );
}

// Demonstration questions only.
// Replace these with real 2012 questions.
const demoQuestions = <MCQ>[
  MCQ(id: 1, question: 'বাংলাদেশের সর্বোচ্চ আইন কোনটি?',
    options: ['দণ্ডবিধি', 'সংবিধান', 'দেওয়ানি কার্যবিধি', 'সাক্ষ্য আইন'],
    answer: 1, difficulty: 'simple'),
  MCQ(id: 2, question: 'বাংলাদেশের সংবিধান কার্যকর হয় কবে?',
    options: ['২৬ মার্চ ১৯৭১', '১৬ ডিসেম্বর ১৯৭১',
      '৪ নভেম্বর ১৯৭২', '১৬ ডিসেম্বর ১৯৭২'],
    answer: 3, difficulty: 'simple'),
  MCQ(id: 3, question: 'দেওয়ানি কার্যবিধি কোন সালের আইন?',
    options: ['১৮৬০', '১৮৭২', '১৯০৮', '১৮৯৮'],
    answer: 2, difficulty: 'easy'),
  MCQ(id: 4, question: 'বাংলাদেশের দণ্ডবিধি কোন সালের?',
    options: ['১৮৬০', '১৮৭২', '১৯০৮', '১৮৯৮'],
    answer: 0, difficulty: 'simple'),
  MCQ(id: 5, question: 'সাক্ষ্য আইন কোন সালের?',
    options: ['১৮৬০', '১৮৭২', '১৯০৮', '১৯০৯'],
    answer: 1, difficulty: 'simple'),
  MCQ(id: 6, question: 'ফৌজদারি কার্যবিধি কোন সালের?',
    options: ['১৮৬০', '১৮৭২', '১৮৯৮', '১৯০৮'],
    answer: 2, difficulty: 'simple'),
  MCQ(id: 7, question: 'বাংলাদেশের সুপ্রিম কোর্টের বিভাগ কয়টি?',
    options: ['একটি', 'দুটি', 'তিনটি', 'চারটি'],
    answer: 1, difficulty: 'simple'),
  MCQ(id: 8, question: 'সংবিধানের ১০২ অনুচ্ছেদ মূলত কোন বিষয়ে?',
    options: ['রিট এখতিয়ার', 'রাষ্ট্রপতি',
      'অর্থ বিল', 'নির্বাচন'],
    answer: 0, difficulty: 'easy'),
  MCQ(id: 9, question: 'বাংলাদেশের রাষ্ট্রের নাম কী?',
    options: ['বাংলাদেশ প্রজাতন্ত্র', 'গণপ্রজাতন্ত্রী বাংলাদেশ',
      'বাংলাদেশ ইউনিয়ন', 'বাংলাদেশ রাজ্য'],
    answer: 1, difficulty: 'simple'),
  MCQ(id: 10, question: 'বাংলাদেশের আইনসভা কী নামে পরিচিত?',
    options: ['জাতীয় সংসদ', 'সুপ্রিম কোর্ট',
      'মন্ত্রিপরিষদ', 'নির্বাচন কমিশন'],
    answer: 0, difficulty: 'simple'),
];

class QuestionBank {
  static final Map<int, List<MCQ>> _cache = {};

  static Future<List<MCQ>> load(int year) async {
    if (_cache.containsKey(year)) return _cache[year]!;

    if (year == 2012) {
      try {
        final raw = await rootBundle.loadString(
          'assets/data/questions_2012.json',
        );
        final List<dynamic> data = jsonDecode(raw);
        final questions = data
            .map((e) => MCQ.fromJson(Map<String, dynamic>.from(e)))
            .toList();

        if (questions.isNotEmpty) {
          _cache[year] = questions;
          return questions;
        }
      } catch (_) {
        // Empty or invalid JSON falls back to demonstration data.
      }

      final generated = List.generate(
        100,
        (i) {
          final q = demoQuestions[i % demoQuestions.length];
          return MCQ(
            id: i + 1,
            question: '[DEMO ${i + 1}] ${q.question}',
            options: q.options,
            answer: q.answer,
            explanation: q.explanation,
            difficulty: q.difficulty,
          );
        },
      );
      _cache[year] = generated;
      return generated;
    }

    return [];
  }

  static void clearCache() => _cache.clear();
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final modes = [
      _Mode('Reading Mode', 'Read MCQs like a book',
        Icons.menu_book_rounded, blue, const ReadingScreen()),
      _Mode('Exam Mode', '100 MCQ + OMR Sheet',
        Icons.fact_check_rounded, green, const ExamSetupScreen()),
      _Mode('Advance Mode', 'Hard • Easy • Simple • 9 sets',
        Icons.psychology_alt_rounded, const Color(0xFFFF851B),
        const AdvanceScreen()),
      _Mode('2027 MCQ Mode', 'Future practice question bank',
        Icons.auto_awesome_rounded, purple, const FutureScreen()),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: navy,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bangladesh Bar Council',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            Text('PREPARATION APP',
              style: TextStyle(fontSize: 11, color: gold, letterSpacing: 1.4)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'About',
            onPressed: () => showAboutDialog(
              context: context,
              applicationName: 'Biplob BAR Plan',
              applicationVersion: '1.0.0',
              children: const [
                Text('Bar Council MCQ practice application.'),
              ],
            ),
            icon: const Icon(Icons.account_circle_outlined, color: gold),
          ),
        ],
      ),
      drawer: Drawer(
        backgroundColor: navy2,
        child: ListView(
          children: [
            const DrawerHeader(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.balance, color: gold, size: 42),
                  SizedBox(height: 12),
                  Text('Biplob BAR Plan',
                    style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
                  Text('Prepare • Practise • Achieve'),
                ],
              ),
            ),
            for (final m in modes)
              ListTile(
                leading: Icon(m.icon, color: m.color),
                title: Text(m.title),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context,
                    MaterialPageRoute(builder: (_) => m.page));
                },
              ),
          ],
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [navy2, Color(0xFF183B65)],
                ),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: gold.withOpacity(.45)),
              ),
              child: const Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('WELCOME, FUTURE ADVOCATE',
                          style: TextStyle(color: gold, fontSize: 11)),
                        SizedBox(height: 10),
                        Text('Your journey to the Bar starts here.',
                          style: TextStyle(fontSize: 19,
                            fontWeight: FontWeight.bold)),
                        SizedBox(height: 8),
                        Text('Read. Practise. Improve.',
                          style: TextStyle(color: Colors.white70)),
                      ],
                    ),
                  ),
                  Icon(Icons.balance, size: 64, color: gold),
                ],
              ),
            ),
            const SizedBox(height: 22),
            const Text('CHOOSE YOUR MODE',
              style: TextStyle(color: gold, fontWeight: FontWeight.bold,
                letterSpacing: 1.3)),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: modes.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: .92,
              ),
              itemBuilder: (context, i) {
                final m = modes[i];
                return InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => m.page)),
                  child: Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: m.color.withOpacity(.14),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: m.color.withOpacity(.75)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(m.icon, color: m.color, size: 34),
                        const Spacer(),
                        Text(m.title,
                          style: const TextStyle(fontWeight: FontWeight.bold,
                            fontSize: 15)),
                        const SizedBox(height: 7),
                        Text(m.subtitle,
                          style: const TextStyle(fontSize: 11,
                            color: Colors.white70)),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.bottomRight,
                          child: Icon(Icons.arrow_forward,
                            color: m.color, size: 19),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(17),
              decoration: BoxDecoration(
                color: navy2,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('YOUR PREPARATION',
                    style: TextStyle(color: gold,
                      fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text('2012 demo bank • 100 test questions',
                    style: TextStyle(color: Colors.white70)),
                  SizedBox(height: 10),
                  LinearProgressIndicator(
                    value: 0, minHeight: 7,
                    backgroundColor: Colors.white12,
                    color: gold,
                  ),
                  SizedBox(height: 8),
                  Text('Progress will be tracked in a later version.',
                    style: TextStyle(fontSize: 11, color: Colors.white60)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Mode {
  final String title, subtitle;
  final IconData icon;
  final Color color;
  final Widget page;
  const _Mode(this.title, this.subtitle, this.icon, this.color, this.page);
}

const years = [2012, 2013, 2014, 2015, 2016, 2017, 2018, 2019,
  2020, 2021, 2022, 2023, 2024, 2025, 2026];

class ReadingScreen extends StatefulWidget {
  const ReadingScreen({super.key});
  @override
  State<ReadingScreen> createState() => _ReadingScreenState();
}

class _ReadingScreenState extends State<ReadingScreen> {
  int year = 2012, index = 0;
  List<MCQ> questions = [];
  bool loading = true;

  Future<void> load() async {
    setState(() { loading = true; index = 0; });
    questions = await QuestionBank.load(year);
    if (mounted) setState(() => loading = false);
  }

  @override
  void initState() { super.initState(); load(); }

  @override
  Widget build(BuildContext context) {
    final q = questions.isEmpty ? null : questions[index];
    return Scaffold(
      appBar: AppBar(title: const Text('Reading Mode')),
      body: loading
        ? const Center(child: CircularProgressIndicator(color: gold))
        : questions.isEmpty
          ? _emptyYear(year)
          : Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    DropdownButton<int>(
                      value: year,
                      dropdownColor: navy2,
                      items: years.map((y) => DropdownMenuItem(
                        value: y, child: Text('$y'),
                      )).toList(),
                      onChanged: (v) { if (v != null) {
                        setState(() => year = v); load();
                      }},
                    ),
                    const Spacer(),
                    Text('${index + 1} / ${questions.length}',
                      style: const TextStyle(color: gold)),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(18),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF6E4),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: gold, width: 2),
                    ),
                    child: DefaultTextStyle(
                      style: const TextStyle(color: Color(0xFF252525),
                        fontSize: 16, height: 1.55),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Center(
                            child: Text('BANGLADESH BAR COUNCIL',
                              style: TextStyle(fontWeight: FontWeight.bold,
                                color: navy, fontSize: 14)),
                          ),
                          const Divider(color: gold, height: 28),
                          Text('Question ${q!.id}',
                            style: const TextStyle(fontWeight: FontWeight.bold,
                              color: navy)),
                          const SizedBox(height: 12),
                          Text(q.question,
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 18),
                          for (int i = 0; i < q.options.length; i++)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Text(
                                '${String.fromCharCode(65 + i)}. ${q.options[i]}',
                                style: TextStyle(
                                  color: i == q.answer
                                    ? const Color(0xFF148044)
                                    : const Color(0xFF252525),
                                  fontWeight: i == q.answer
                                    ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: green.withOpacity(.14),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Correct Answer: ${String.fromCharCode(65 + q.answer)}',
                              style: const TextStyle(color: Color(0xFF14713C),
                                fontWeight: FontWeight.bold),
                            ),
                          ),
                          if (q.explanation.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Text(q.explanation),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(child: OutlinedButton(
                      onPressed: index > 0
                        ? () => setState(() => index--) : null,
                      child: const Text('← Previous'),
                    )),
                    const SizedBox(width: 10),
                    Expanded(child: FilledButton(
                      onPressed: index < questions.length - 1
                        ? () => setState(() => index++) : null,
                      child: const Text('Next →'),
                    )),
                  ],
                ),
              ),
            ],
          ),
    );
  }
}

Widget _emptyYear(int year) => Center(
  child: Padding(
    padding: const EdgeInsets.all(24),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.menu_book, size: 60, color: gold),
        const SizedBox(height: 16),
        Text('$year সালের প্রশ্ন এখনো যোগ করা হয়নি.',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18)),
        const SizedBox(height: 8),
        const Text('প্রশ্নের JSON ডেটা যোগ করলে এই সাল সক্রিয় হবে.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70)),
      ],
    ),
  ),
);

class ExamSetupScreen extends StatefulWidget {
  const ExamSetupScreen({super.key});
  @override
  State<ExamSetupScreen> createState() => _ExamSetupScreenState();
}

class _ExamSetupScreenState extends State<ExamSetupScreen> {
  int year = 2012;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Exam Mode')),
    body: Padding(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.fact_check, color: green, size: 64),
          const SizedBox(height: 18),
          const Text('Full Model Test',
            style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          const Text('100 MCQ • 100 marks • Negative marking 0.25',
            style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 22),
          const Text('Select examination year'),
          DropdownButton<int>(
            value: year,
            isExpanded: true,
            dropdownColor: navy2,
            items: years.map((y) => DropdownMenuItem(
              value: y, child: Text('$y'),
            )).toList(),
            onChanged: (v) { if (v != null) setState(() => year = v); },
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              icon: const Icon(Icons.play_arrow),
              label: const Text('START EXAM'),
              onPressed: () async {
                final qs = await QuestionBank.load(year);
                if (!context.mounted) return;
                if (qs.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(
                      'No questions available for $year.')),
                  );
                  return;
                }
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => ExamScreen(year: year, questions: qs),
                ));
              },
            ),
          ),
        ],
      ),
    ),
  );
}

class ExamScreen extends StatefulWidget {
  final int year;
  final List<MCQ> questions;
  const ExamScreen({super.key, required this.year, required this.questions});
  @override
  State<ExamScreen> createState() => _ExamScreenState();
}

class _ExamScreenState extends State<ExamScreen> {
  final Map<int, int> answers = {};
  int index = 0;
  bool submitted = false;

  int get correct => answers.entries.where(
    (e) => widget.questions[e.key].answer == e.value).length;
  int get wrong => answers.length - correct;
  int get unanswered => widget.questions.length - answers.length;
  double get score => correct - wrong * .25;

  void finish() {
    setState(() => submitted = true);
  }

  @override
  Widget build(BuildContext context) {
    final qs = widget.questions;
    final q = qs[index];

    return Scaffold(
      appBar: AppBar(
        title: Text(submitted ? 'Exam Result' : 'Exam • ${widget.year}'),
        actions: [
          if (!submitted)
            TextButton(
              onPressed: () => showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Submit exam?'),
                  content: Text(
                    'Answered: ${answers.length}/${qs.length}\n'
                    'Unanswered: $unanswered'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Continue'),
                    ),
                    FilledButton(
                      onPressed: () {
                        Navigator.pop(context);
                        finish();
                      },
                      child: const Text('Submit'),
                    ),
                  ],
                ),
              ),
              child: const Text('SUBMIT',
                style: TextStyle(color: gold)),
            ),
        ],
      ),
      body: submitted
        ? _resultView()
        : Column(
          children: [
            LinearProgressIndicator(
              value: (index + 1) / qs.length,
              color: gold, backgroundColor: Colors.white12,
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Text('Question ${index + 1}/${qs.length}'),
                  const Spacer(),
                  Text('Answered ${answers.length}',
                    style: const TextStyle(color: gold)),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: navy2,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(q.question,
                        style: const TextStyle(fontSize: 18,
                          fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 12),
                    for (int i = 0; i < q.options.length; i++)
                      Card(
                        color: answers[index] == i
                          ? blue.withOpacity(.24) : navy2,
                        child: RadioListTile<int>(
                          value: i,
                          groupValue: answers[index],
                          onChanged: (v) {
                            if (v != null) setState(() => answers[index] = v);
                          },
                          title: Text(
                            '${String.fromCharCode(65 + i)}. ${q.options[i]}'),
                        ),
                      ),
                    const SizedBox(height: 18),
                    const Text('OMR ANSWER SHEET',
                      style: TextStyle(color: red, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    _omr(qs, answers, null, null),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(child: OutlinedButton(
                    onPressed: index > 0 ? () => setState(() => index--) : null,
                    child: const Text('Previous'),
                  )),
                  const SizedBox(width: 8),
                  Expanded(child: FilledButton(
                    onPressed: index < qs.length - 1
                      ? () => setState(() => index++)
                      : () => showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Last question'),
                          content: const Text('Submit the exam now?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Review'),
                            ),
                            FilledButton(
                              onPressed: () {
                                Navigator.pop(context);
                                finish();
                              },
                              child: const Text('Submit'),
                            ),
                          ],
                        ),
                      ),
                    child: Text(index < qs.length - 1 ? 'Next' : 'Finish'),
                  )),
                ],
              ),
            ),
          ],
        ),
    );
  }

  Widget _resultView() => ListView(
    padding: const EdgeInsets.all(18),
    children: [
      const Icon(Icons.emoji_events, size: 76, color: gold),
      const Center(child: Text('TEST COMPLETED',
        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold))),
      const SizedBox(height: 18),
      _stat('Total Questions', '${widget.questions.length}', gold),
      _stat('Correct Answers', '$correct', green),
      _stat('Wrong Answers', '$wrong', red),
      _stat('Unanswered', '$unanswered', Colors.orange),
      _stat('Final Score', '${score.toStringAsFixed(2)} / 100', gold),
      const SizedBox(height: 18),
      const Text('OMR REVIEW',
        style: TextStyle(color: red, fontWeight: FontWeight.bold)),
      const SizedBox(height: 10),
      _omr(widget.questions, answers, correct, wrong),
      const SizedBox(height: 20),
      const Text('ANSWER REVIEW',
        style: TextStyle(color: gold, fontWeight: FontWeight.bold)),
      for (int i = 0; i < widget.questions.length; i++)
        Card(
          color: navy2,
          child: ListTile(
            leading: Icon(
              !answers.containsKey(i) ? Icons.remove_circle_outline
                : answers[i] == widget.questions[i].answer
                  ? Icons.check_circle : Icons.cancel,
              color: !answers.containsKey(i) ? Colors.orange
                : answers[i] == widget.questions[i].answer ? green : red,
            ),
            title: Text('${i + 1}. ${widget.questions[i].question}'),
            subtitle: Text(
              'Your answer: ${answers.containsKey(i)
                ? String.fromCharCode(65 + answers[i]!)
                : "Not answered"}'
              ' • Correct: ${String.fromCharCode(65 + widget.questions[i].answer)}'),
          ),
        ),
      FilledButton(
        onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
        child: const Text('Back to Home'),
      ),
    ],
  );

  Widget _stat(String label, String value, Color color) => Card(
    color: navy2,
    child: ListTile(
      leading: Icon(Icons.circle, color: color, size: 13),
      title: Text(label),
      trailing: Text(value,
        style: TextStyle(color: color, fontWeight: FontWeight.bold)),
    ),
  );
}

Widget _omr(List<MCQ> qs, Map<int, int> answers,
  int? correct, int? wrong) {
  return Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF4F4),
      border: Border.all(color: red, width: 2),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Center(child: Text('OMR • ANSWER SHEET',
          style: TextStyle(color: red, fontWeight: FontWeight.bold))),
        const Divider(color: red),
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: List.generate(qs.length, (i) {
            final chosen = answers[i];
            final isRight = chosen != null && chosen == qs[i].answer;
            final isWrong = chosen != null && !isRight;
            final color = correct == null
              ? (chosen == null ? Colors.black38 : red)
              : isRight ? green : isWrong ? red : Colors.black38;
            return Container(
              width: 54,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: color, width: 1.2),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Column(
                children: [
                  Text('${i + 1}',
                    style: const TextStyle(color: Colors.black,
                      fontSize: 11, fontWeight: FontWeight.bold)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(4, (j) {
                      final selected = chosen == j;
                      return Text(
                        selected
                          ? (correct == null ? '●'
                            : isRight ? '✓' : '✕')
                          : String.fromCharCode(65 + j),
                        style: TextStyle(
                          fontSize: 10,
                          color: selected ? color : Colors.black54,
                          fontWeight: selected ? FontWeight.bold : null,
                        ),
                      );
                    }),
                  ),
                  if (correct != null && chosen == null)
                    const Text('—', style: TextStyle(
                      color: Colors.black45, fontSize: 10)),
                ],
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        const Text('✓ Correct     ✕ Wrong     — Unanswered',
          style: TextStyle(color: Colors.black87, fontSize: 11)),
      ],
    ),
  );
}

class AdvanceScreen extends StatelessWidget {
  const AdvanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final modes = [
      ('Hard Mode', '3 sets • Most difficult questions', red, 'hard'),
      ('Easy Mode', '3 sets • Moderate difficulty', blue, 'easy'),
      ('Simple Mode', '3 sets • Basic concepts', green, 'simple'),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Advance Mode')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('9 SET QUESTION BANK',
            style: TextStyle(color: gold, fontSize: 20,
              fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Choose your difficulty level.',
            style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 18),
          for (final m in modes)
            Card(
              color: m.$3.withOpacity(.17),
              child: ListTile(
                contentPadding: const EdgeInsets.all(15),
                leading: Icon(Icons.workspace_premium,
                  color: m.$3, size: 34),
                title: Text(m.$1,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(m.$2),
                trailing: const Icon(Icons.arrow_forward),
                onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) =>
                    SetSelectionScreen(difficulty: m.$4))),
              ),
            ),
          const SizedBox(height: 12),
          const Text('Question difficulty must be assigned using reviewed '
            'historical questions. Demo data is not an official classification.',
            style: TextStyle(color: Colors.white60, fontSize: 12)),
        ],
      ),
    );
  }
}

class SetSelectionScreen extends StatelessWidget {
  final String difficulty;
  const SetSelectionScreen({super.key, required this.difficulty});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('${difficulty.toUpperCase()} SETS')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (int i = 1; i <= 3; i++)
          Card(
            color: navy2,
            child: ListTile(
              leading: const Icon(Icons.quiz, color: gold),
              title: Text('Set $i'),
              subtitle: const Text('Question set'),
              trailing: const Icon(Icons.arrow_forward),
              onTap: () async {
                final qs = await QuestionBank.load(2012);
                if (!context.mounted) return;
                final filtered = qs.where((q) =>
                  q.difficulty == difficulty).toList();
                final setQuestions = filtered.isEmpty
                  ? qs.take(30).toList()
                  : filtered.take(30).toList();
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => ExamScreen(
                    year: 2012, questions: setQuestions),
                ));
              },
            ),
          ),
      ],
    ),
  );
}

class FutureScreen extends StatelessWidget {
  const FutureScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('2027 MCQ Mode')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF30206C), Color(0xFF12518D)],
            ),
            borderRadius: BorderRadius.circular(22),
          ),
          child: const Column(
            children: [
              Icon(Icons.psychology_alt, size: 70, color: gold),
              SizedBox(height: 12),
              Text('2027 MCQ PRACTICE',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('Pattern-based preparation',
                style: TextStyle(color: Colors.white70)),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text('Planned features',
          style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        for (final s in [
          'Historical question trend analysis',
          'Topic-wise question distribution',
          'Difficulty-based practice',
          'New practice questions with verified answers',
        ])
          ListTile(
            leading: const Icon(Icons.check_circle, color: green),
            title: Text(s),
          ),
        const SizedBox(height: 12),
        const Text(
          'This mode currently shows a feature preview. '
          'AI-generated questions and pattern analysis are not connected yet. '
          'Generated questions should be checked against current Bangladeshi law.',
          style: TextStyle(color: Colors.white60),
        ),
      ],
    ),
  );
}
