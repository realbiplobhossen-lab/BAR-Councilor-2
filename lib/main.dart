import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BarPrepApp());
}

const navy = Color(0xFF07172E);
const navy2 = Color(0xFF102B4E);
const gold = Color(0xFFFFC857);
const green = Color(0xFF20B875);
const red = Color(0xFFE74452);
const purple = Color(0xFF7953F5);
const blue = Color(0xFF2678F5);
const orange = Color(0xFFFF851B);


const List<int> examYears = [
  2012,
  2013,
  2015,
  2017,
  2020,
  2022,
  2023,
  2025,
  2026,
];


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

  factory MCQ.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final question = json['question'];
    final rawOptions = json['options'];
    final answer = json['answer'];

    if (id is! int || id < 1) {
      throw const FormatException(
        'প্রশ্নের id অবশ্যই ধনাত্মক পূর্ণসংখ্যা হতে হবে।',
      );
    }

    if (question is! String || question.trim().isEmpty) {
      throw const FormatException(
        'প্রশ্নের question ফাঁকা রাখা যাবে না।',
      );
    }

    if (rawOptions is! List ||
        rawOptions.length != 4 ||
        rawOptions.any(
          (option) => option is! String || option.trim().isEmpty,
        )) {
      throw const FormatException(
        'প্রতিটি MCQ-তে চারটি বৈধ options থাকতে হবে।',
      );
    }

    if (answer is! int || answer < 0 || answer > 3) {
      throw const FormatException(
        'answer-এর মান 0, 1, 2 অথবা 3 হতে হবে।',
      );
    }

    final explanation = json['explanation'] ?? '';
    final difficulty = json['difficulty'] ?? 'simple';

    if (explanation is! String || difficulty is! String) {
      throw const FormatException(
        'explanation এবং difficulty অবশ্যই String হতে হবে।',
      );
    }

    final normalizedDifficulty = difficulty.toLowerCase().trim();

    if (!['hard', 'easy', 'simple'].contains(normalizedDifficulty)) {
      throw const FormatException(
        'difficulty হবে hard, easy অথবা simple।',
      );
    }

    return MCQ(
      id: id,
      question: question.trim(),
      options: List<String>.from(rawOptions),
      answer: answer,
      explanation: explanation,
      difficulty: normalizedDifficulty,
    );
  }
}


class QuestionBank {
  static const List<String> optionKeys = [
    'ক',
    'খ',
    'গ',
    'ঘ',
  ];

  static Future<List<MCQ>> load(int year) async {
    if (!examYears.contains(year)) {
      throw ArgumentError('Invalid exam year: $year');
    }

    final path = 'assets/data/questions_$year.json';
    final raw = await rootBundle.loadString(path);
    final decoded = jsonDecode(raw);

    // মূল JSON একটি Object হতে হবে।
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException(
        'JSON-এর মূল ডেটা একটি Object হতে হবে।',
      );
    }

    // প্রশ্নগুলো questions নামের List-এর মধ্যে আছে।
    final rawQuestions = decoded['questions'];

    if (rawQuestions is! List) {
      throw const FormatException(
        'JSON-এ questions নামে একটি List থাকতে হবে।',
      );
    }

    return rawQuestions.map<MCQ>((item) {
      if (item is! Map) {
        throw const FormatException(
          'একটি প্রশ্নের ডেটা সঠিক নয়।',
        );
      }

      final question = Map<String, dynamic>.from(item);
      final rawOptions = question['options'];

      // JSON-এর অপশন Map থেকে চারটি অপশন বের করা।
      late final List<String> options;

      if (rawOptions is Map) {
        options = optionKeys.map((key) {
          final value = rawOptions[key];

          if (value == null) {
            throw FormatException(
              'প্রশ্ন ${question['id']}: $key অপশন পাওয়া যায়নি।',
            );
          }

          return value.toString();
        }).toList();
      } else if (rawOptions is List) {
        options = rawOptions
            .map((option) => option.toString())
            .toList();
      } else {
        throw FormatException(
          'প্রশ্ন ${question['id']}: options সঠিক নয়।',
        );
      }

      if (options.length != 4) {
        throw FormatException(
          'প্রশ্ন ${question['id']}: ঠিক ৪টি অপশন থাকতে হবে।',
        );
      }

      // বাংলা উত্তর ক/খ/গ/ঘ-কে 0/1/2/3-এ রূপান্তর।
      final rawAnswer = question['answer'];
      late final int answerIndex;

      if (rawAnswer is int) {
        answerIndex = rawAnswer;
      } else {
        final answerLetter = rawAnswer.toString().trim();
        answerIndex = optionKeys.indexOf(answerLetter);
      }

      if (answerIndex < 0 || answerIndex > 3) {
        throw FormatException(
          'প্রশ্ন ${question['id']}: সঠিক উত্তর শনাক্ত করা যায়নি।',
        );
      }

      // বিদ্যমান MCQ.fromJson()-এর উপযোগী ডেটা তৈরি।
      question['options'] = options;
      question['answer'] = answerIndex;
      question['explanation'] ??= '';
      question['difficulty'] ??= 'simple';

      return MCQ.fromJson(question);
    }).toList();
  }
}


class BarPrepApp extends StatelessWidget {
  const BarPrepApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Biplob BAR Plan',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: navy,
        colorScheme: ColorScheme.fromSeed(
          seedColor: gold,
          brightness: Brightness.dark,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: navy,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _timer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const HomeScreen(),
        ),
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [navy, Color(0xFF153B65), navy],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(.06),
                  border: Border.all(color: gold, width: 2),
                ),
                child: const Icon(
                  Icons.account_balance,
                  color: gold,
                  size: 94,
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'BANGLADESH\nBAR COUNCIL',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  height: 1.25,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'PREPARATION APP',
                style: TextStyle(
                  color: gold,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Prepare • Practise • Achieve',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 42),
              const SizedBox(
                width: 150,
                child: LinearProgressIndicator(
                  color: gold,
                  backgroundColor: Colors.white12,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'YOUR SUCCESS, OUR GOAL',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ModeInfo {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Widget page;

  const ModeInfo(
    this.title,
    this.subtitle,
    this.icon,
    this.color,
    this.page,
  );
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final modes = <ModeInfo>[
      ModeInfo(
        'Reading Mode',
        'বইয়ের মতো MCQ পড়ুন',
        Icons.menu_book_rounded,
        blue,
        const ReadingScreen(),
      ),
      ModeInfo(
        'Exam Mode',
        'MCQ পরীক্ষা ও OMR',
        Icons.fact_check_rounded,
        green,
        const ExamSetupScreen(),
      ),
      ModeInfo(
        'Advance Mode',
        'Hard • Easy • Simple',
        Icons.psychology_alt_rounded,
        orange,
        const AdvanceScreen(),
      ),
      ModeInfo(
        '2027 MCQ Mode',
        'ভবিষ্যৎ প্রস্তুতি',
        Icons.auto_awesome_rounded,
        purple,
        const FutureScreen(),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bangladesh Bar Council',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 17,
              ),
            ),
            Text(
              'PREPARATION APP',
              style: TextStyle(
                color: gold,
                fontSize: 10,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'About',
            icon: const Icon(
              Icons.account_circle_outlined,
              color: gold,
            ),
            onPressed: () => showAboutDialog(
              context: context,
              applicationName: 'Biplob BAR Plan',
              applicationVersion: '1.0.0',
            ),
          ),
        ],
      ),
      drawer: Drawer(
        backgroundColor: navy2,
        child: SafeArea(
          child: ListView(
            children: [
              const DrawerHeader(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.account_balance,
                      color: gold,
                      size: 44,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Biplob BAR Plan',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text('Prepare • Practise • Achieve'),
                  ],
                ),
              ),
              for (final mode in modes)
                ListTile(
                  leading: Icon(mode.icon, color: mode.color),
                  title: Text(mode.title),
                  subtitle: Text(mode.subtitle),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => mode.page,
                      ),
                    );
                  },
                ),
              const Divider(color: Colors.white24),
              const ListTile(
                leading: Icon(Icons.info_outline, color: gold),
                title: Text('About App'),
                subtitle: Text(
                  'Bangladesh Bar Council preparation',
                ),
              ),
            ],
          ),
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
                  colors: [navy2, Color(0xFF1B426E)],
                ),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: gold.withOpacity(.45),
                ),
              ),
              child: const Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'WELCOME, FUTURE ADVOCATE',
                          style: TextStyle(
                            color: gold,
                            fontSize: 11,
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Your journey to the Bar starts here.',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Read. Practise. Improve.',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.balance, color: gold, size: 58),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'CHOOSE YOUR MODE',
              style: TextStyle(
                color: gold,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.3,
              ),
            ),
            const SizedBox(height: 14),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: modes.length,
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: .84,
              ),
              itemBuilder: (context, i) {
                final mode = modes[i];

                return Material(
                  color: mode.color.withOpacity(.13),
                  borderRadius: BorderRadius.circular(20),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => mode.page,
                      ),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: mode.color.withOpacity(.8),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            mode.icon,
                            size: 36,
                            color: mode.color,
                          ),
                          const Spacer(),
                          Text(
                            mode.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            mode.subtitle,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Icon(
                              Icons.arrow_forward_rounded,
                              color: mode.color,
                            ),
                          ),
                        ],
                      ),
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
                  Text(
                    'YOUR PREPARATION',
                    style: TextStyle(
                      color: gold,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'প্রশ্ন যোগ হলে সংশ্লিষ্ট বছরের অনুশীলন করতে পারবে।',
                    style: TextStyle(color: Colors.white70),
                  ),
                  SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: 0,
                    color: gold,
                    backgroundColor: Colors.white12,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Prepare today • Achieve tomorrow',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ReadingScreen extends StatefulWidget {
  const ReadingScreen({super.key});

  @override
  State<ReadingScreen> createState() => _ReadingScreenState();
}

class _ReadingScreenState extends State<ReadingScreen> {
  int year = 2012;
  int index = 0;
  List<MCQ> questions = [];
  bool loading = true;
  String? loadError;

  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    loadQuestions();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> loadQuestions() async {
    setState(() {
      loading = true;
      index = 0;
      questions = [];
      loadError = null;
    });

    try {
      final loaded = await QuestionBank.load(year);

      if (!mounted) return;

      setState(() {
        questions = loaded;
        loading = false;
      });

      if (_pageController.hasClients) {
        _pageController.jumpToPage(0);
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
        loadError = e.toString();
      });
    }
  }

  void goToPage(int page) {
    if (page < 0 || page >= questions.length) return;

    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOut,
    );
  }

  Future<void> selectYear() async {
    final selected = await showDialog<int>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        backgroundColor: navy2,
        title: const Text('পরীক্ষার সাল নির্বাচন'),
        children: [
          for (final y in years)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(dialogContext, y),
              child: Text(
                '$y',
                style: TextStyle(
                  color: y == year ? gold : Colors.white,
                  fontWeight: y == year
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
            ),
        ],
      ),
    );

    if (selected != null && selected != year && mounted) {
      setState(() => year = selected);
      await loadQuestions();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reading Mode'),
        actions: [
          IconButton(
            tooltip: 'বছর পরিবর্তন',
            icon: const Icon(Icons.tune, color: gold),
            onPressed: selectYear,
          ),
        ],
      ),
      body: SafeArea(
        child: loading
            ? const Center(
                child: CircularProgressIndicator(color: gold),
              )
            : loadError != null
                ? _readingError()
                : questions.isEmpty
                    ? _emptyYear(year)
                    : Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(
                              16, 12, 16, 8,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: navy2,
                                    borderRadius:
                                        BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'সাল: $year',
                                    style: const TextStyle(
                                      color: gold,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '${index + 1} / ${questions.length}',
                                  style: const TextStyle(color: gold),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: PageView.builder(
                              controller: _pageController,
                              itemCount: questions.length,
                              onPageChanged: (newIndex) {
                                setState(() => index = newIndex);
                              },
                              itemBuilder: (context, i) {
                                final q = questions[i];

                                return SingleChildScrollView(
                                  padding: const EdgeInsets.fromLTRB(
                                    14, 8, 14, 14,
                                  ),
                                  child: Container(
                                    width: double.infinity,
                                    constraints: const BoxConstraints(
                                      minHeight: 390,
                                    ),
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFF6E4),
                                      borderRadius:
                                          BorderRadius.circular(10),
                                      border: Border.all(
                                        color: gold,
                                        width: 2,
                                      ),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Colors.black26,
                                          blurRadius: 10,
                                          offset: Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: DefaultTextStyle(
                                      style: const TextStyle(
                                        color: Color(0xFF252525),
                                        fontSize: 16,
                                        height: 1.55,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Center(
                                            child: Text(
                                              'BANGLADESH BAR COUNCIL',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                fontWeight:
                                                    FontWeight.bold,
                                                color: navy,
                                                fontSize: 15,
                                              ),
                                            ),
                                          ),
                                          Center(
                                            child: Text(
                                              'MCQ PRACTICE • $year',
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: Color(0xFF666666),
                                              ),
                                            ),
                                          ),
                                          const Divider(
                                            color: gold,
                                            height: 28,
                                          ),
                                          Text(
                                            'প্রশ্ন ${q.id}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: navy,
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            q.question,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 18),
                                          for (int j = 0;
                                              j < q.options.length;
                                              j++)
                                            Padding(
                                              padding:
                                                  const EdgeInsets.only(
                                                bottom: 10,
                                              ),
                                              child: Text(
                                                '${String.fromCharCode(65 + j)}. ${q.options[j]}',
                                                style: TextStyle(
                                                  color: j == q.answer
                                                      ? const Color(
                                                          0xFF14713C,
                                                        )
                                                      : const Color(
                                                          0xFF252525,
                                                        ),
                                                  fontWeight:
                                                      j == q.answer
                                                          ? FontWeight.bold
                                                          : FontWeight.normal,
                                                ),
                                              ),
                                            ),
                                          const SizedBox(height: 12),
                                          Container(
                                            width: double.infinity,
                                            padding:
                                                const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color:
                                                  green.withOpacity(.14),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              'সঠিক উত্তর: ${String.fromCharCode(65 + q.answer)}',
                                              style: const TextStyle(
                                                color: Color(0xFF14713C),
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          if (q.explanation.isNotEmpty) ...[
                                            const SizedBox(height: 12),
                                            Text(
                                              'ব্যাখ্যা: ${q.explanation}',
                                            ),
                                          ],
                                          const SizedBox(height: 20),
                                          const Center(
                                            child: Text(
                                              '• • • • •',
                                              style: TextStyle(
                                                color: Color(0xFF999999),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: index > 0
                                        ? () => goToPage(index - 1)
                                        : null,
                                    icon: const Icon(Icons.arrow_back),
                                    label: const Text('Previous'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: FilledButton.icon(
                                    onPressed:
                                        index < questions.length - 1
                                            ? () => goToPage(index + 1)
                                            : null,
                                    icon: const Icon(
                                      Icons.arrow_forward,
                                    ),
                                    label: const Text('Next'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
      ),
    );
  }

  Widget _readingError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              color: red,
              size: 60,
            ),
            const SizedBox(height: 14),
            const Text(
              'প্রশ্ন লোড করা যায়নি',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              loadError!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: loadQuestions,
              icon: const Icon(Icons.refresh),
              label: const Text('আবার চেষ্টা করুন'),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _emptyYear(int year) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.menu_book_rounded,
            size: 64,
            color: gold,
          ),
          const SizedBox(height: 16),
          Text(
            '$year সালের প্রশ্ন এখনো যোগ করা হয়নি।',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 10),
          Text(
            'assets/data/questions_$year.json ফাইলে প্রশ্ন যোগ করুন।',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    ),
  );
}

class ExamSetupScreen extends StatefulWidget {
  const ExamSetupScreen({super.key});

  @override
  State<ExamSetupScreen> createState() => _ExamSetupScreenState();
}

class _ExamSetupScreenState extends State<ExamSetupScreen> {
  int year = 2012;
  bool starting = false;

  Future<void> startExam() async {
    setState(() => starting = true);

    try {
      final questions = await QuestionBank.load(year);

      if (!mounted) return;

      if (questions.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$year সালের প্রশ্ন এখনো যোগ করা হয়নি।'),
          ),
        );
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ExamScreen(
            year: year,
            questions: questions,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('প্রশ্ন লোড করা যায়নি: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => starting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Exam Mode')),
      body: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.fact_check_rounded,
              color: green,
              size: 65,
            ),
            const SizedBox(height: 18),
            const Text(
              'FULL MODEL TEST',
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'প্রকৃত পরীক্ষার মতো MCQ অনুশীলন করুন।',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 22),
            _infoTile('মোট প্রশ্ন', 'লোড করা প্রশ্নের সংখ্যা'),
            _infoTile('প্রতি সঠিক উত্তর', '+১'),
            _infoTile('প্রতি ভুল উত্তর', '−০.২৫'),
            _infoTile('উত্তর না দিলে', '০'),
            const SizedBox(height: 22),
            const Text(
              'পরীক্ষার সাল নির্বাচন করুন',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              value: year,
              dropdownColor: navy2,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                prefixIcon: Icon(
                  Icons.calendar_month,
                  color: gold,
                ),
              ),
              items: years.map((y) {
                return DropdownMenuItem(
                  value: y,
                  child: Text('$y'),
                );
              }).toList(),
              onChanged: starting
                  ? null
                  : (value) {
                      if (value != null) {
                        setState(() => year = value);
                      }
                    },
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: starting ? null : startExam,
                icon: starting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.play_arrow_rounded),
                label: Text(
                  starting ? 'লোড হচ্ছে...' : 'START EXAM',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _infoTile(String title, String value) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: navy2,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(child: Text(title)),
          Text(
            value,
            style: const TextStyle(
              color: gold,
              fontWeight: FontWeight.bold,
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

  const ExamScreen({
    super.key,
    required this.year,
    required this.questions,
  });

  @override
  State<ExamScreen> createState() => _ExamScreenState();
}

class _ExamScreenState extends State<ExamScreen> {
  final Map<int, int> answers = {};

  int index = 0;
  bool submitted = false;

  int get correct {
    return answers.entries.where((entry) {
      return widget.questions[entry.key].answer == entry.value;
    }).length;
  }

  int get wrong => answers.length - correct;

  int get unanswered => widget.questions.length - answers.length;

  double get score => correct - wrong * 0.25;

  Future<void> confirmSubmit() async {
    final shouldSubmit = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('পরীক্ষা জমা দেবেন?'),
        content: Text(
          'মোট প্রশ্ন: ${widget.questions.length}\n'
          'উত্তর দিয়েছেন: ${answers.length}\n'
          'উত্তর বাকি: $unanswered\n\n'
          'জমা দিলে ফলাফল দেখা যাবে।',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('ফিরে যান'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('জমা দিন'),
          ),
        ],
      ),
    );

    if (shouldSubmit == true && mounted) {
      setState(() => submitted = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final qs = widget.questions;
    final q = qs[index];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          submitted ? 'Exam Result' : 'Exam • ${widget.year}',
        ),
        actions: [
          if (!submitted)
            TextButton(
              onPressed: confirmSubmit,
              child: const Text(
                'SUBMIT',
                style: TextStyle(
                  color: gold,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: submitted
          ? _resultView()
          : Column(
              children: [
                LinearProgressIndicator(
                  value: (index + 1) / qs.length,
                  color: gold,
                  backgroundColor: Colors.white12,
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Text('প্রশ্ন ${index + 1}/${qs.length}'),
                      const Spacer(),
                      Text(
                        'উত্তর: ${answers.length}',
                        style: const TextStyle(color: gold),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                    ),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: navy2,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Text(
                          q.question,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            height: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      for (int i = 0; i < q.options.length; i++)
                        Card(
                          color: answers[index] == i
                              ? blue.withOpacity(.25)
                              : navy2,
                          child: RadioListTile<int>(
                            value: i,
                            groupValue: answers[index],
                            activeColor: gold,
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => answers[index] = value);
                              }
                            },
                            title: Text(
                              '${String.fromCharCode(65 + i)}. '
                              '${q.options[i]}',
                            ),
                          ),
                        ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF4F4),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: red),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'OMR ANSWER SHEET',
                              style: TextStyle(
                                color: red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'প্রশ্ন ${index + 1}: '
                              '${answers[index] == null ? "উত্তর দেওয়া হয়নি" : String.fromCharCode(65 + answers[index]!)}',
                              style: const TextStyle(
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _omr(
                              qs,
                              answers,
                              submitted: false,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: index > 0
                              ? () => setState(() => index--)
                              : null,
                          icon: const Icon(Icons.arrow_back),
                          label: const Text('Previous'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: index < qs.length - 1
                              ? () => setState(() => index++)
                              : confirmSubmit,
                          icon: Icon(
                            index < qs.length - 1
                                ? Icons.arrow_forward
                                : Icons.check,
                          ),
                          label: Text(
                            index < qs.length - 1 ? 'Next' : 'Finish',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

    Widget _resultView() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Icon(
          Icons.emoji_events_rounded,
          color: gold,
          size: 76,
        ),
        const Center(
          child: Text(
            'TEST COMPLETED',
            style: TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            '${widget.year} • MCQ Result',
            style: const TextStyle(color: Colors.white70),
          ),
        ),
        const SizedBox(height: 20),
        _resultStat(
          'মোট প্রশ্ন',
          '${widget.questions.length}',
          gold,
        ),
        _resultStat('সঠিক উত্তর', '$correct', green),
        _resultStat('ভুল উত্তর', '$wrong', red),
        _resultStat('উত্তর দেননি', '$unanswered', orange),
        _resultStat(
          'প্রাপ্ত নম্বর',
          score.toStringAsFixed(2),
          gold,
        ),
        const SizedBox(height: 22),
        const Text(
          'OMR ANSWER REVIEW',
          style: TextStyle(
            color: gold,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        _omr(
          widget.questions,
          answers,
          submitted: true,
        ),
        const SizedBox(height: 22),
        const Text(
          'ANSWER REVIEW',
          style: TextStyle(
            color: gold,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        for (int i = 0; i < widget.questions.length; i++)
          Card(
            color: navy2,
            child: ListTile(
              leading: Icon(
                !answers.containsKey(i)
                    ? Icons.remove_circle_outline
                    : answers[i] == widget.questions[i].answer
                        ? Icons.check_circle
                        : Icons.cancel,
                color: !answers.containsKey(i)
                    ? orange
                    : answers[i] == widget.questions[i].answer
                        ? green
                        : red,
              ),
              title: Text(
                '${i + 1}. ${widget.questions[i].question}',
              ),
              subtitle: Text(
                'আপনার উত্তর: '
                '${answers.containsKey(i) ? String.fromCharCode(65 + answers[i]!) : "দেওয়া হয়নি"}'
                '\nসঠিক উত্তর: '
                '${String.fromCharCode(65 + widget.questions[i].answer)}'
                '${widget.questions[i].explanation.isNotEmpty ? "\nব্যাখ্যা: ${widget.questions[i].explanation}" : ""}',
              ),
              isThreeLine: true,
            ),
          ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: () => Navigator.popUntil(
            context,
            (route) => route.isFirst,
          ),
          icon: const Icon(Icons.home),
          label: const Text('Back to Home'),
        ),
      ],
    );
  }

  Widget _resultStat(String label, String value, Color color) {
    return Card(
      color: navy2,
      child: ListTile(
        leading: Icon(Icons.circle, color: color, size: 13),
        title: Text(label),
        trailing: Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

Widget _omr(
  List<MCQ> questions,
  Map<int, int> answers, {
  required bool submitted,
}) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF4F4),
      border: Border.all(color: red, width: 2),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Center(
          child: Text(
            'OMR • ANSWER SHEET',
            style: TextStyle(
              color: red,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const Divider(color: red),
        Wrap(
          spacing: 5,
          runSpacing: 5,
          children: List.generate(questions.length, (i) {
            final chosen = answers[i];
            final isRight =
                chosen != null && chosen == questions[i].answer;
            final isWrong = chosen != null && !isRight;

            final color = !submitted
                ? (chosen == null ? Colors.black38 : blue)
                : isRight
                    ? green
                    : isWrong
                        ? red
                        : Colors.black38;

            return Container(
              width: 55,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(
                  color: color,
                  width: 1.2,
                ),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Column(
                children: [
                  Text(
                    '${i + 1}',
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(4, (j) {
                      final selected = chosen == j;
                      final isCorrectOption =
                          questions[i].answer == j;

                      String symbol = String.fromCharCode(65 + j);
                      Color symbolColor = Colors.black54;

                      if (selected) {
                        if (!submitted) {
                          symbol = '●';
                          symbolColor = blue;
                        } else if (isRight) {
                          symbol = '✓';
                          symbolColor = green;
                        } else {
                          symbol = '✕';
                          symbolColor = red;
                        }
                      } else if (submitted &&
                          isCorrectOption &&
                          isWrong) {
                        symbol = '✓';
                        symbolColor = green;
                      }

                      return Text(
                        symbol,
                        style: TextStyle(
                          color: symbolColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    }),
                  ),
                  if (submitted && chosen == null)
                    const Text(
                      '—',
                      style: TextStyle(
                        color: Colors.black45,
                        fontSize: 10,
                      ),
                    ),
                ],
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        const Text(
          '✓ সঠিক   ✕ ভুল   — উত্তর দেওয়া হয়নি',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 11,
          ),
        ),
      ],
    ),
  );
}

class AdvanceScreen extends StatelessWidget {
  const AdvanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final modes = [
      (
        'Hard Mode',
        'সবচেয়ে কঠিন প্রশ্ন',
        red,
        'hard',
        Icons.psychology_alt_rounded,
      ),
      (
        'Easy Mode',
        'মাঝারি কঠিনতার প্রশ্ন',
        blue,
        'easy',
        Icons.track_changes_rounded,
      ),
      (
        'Simple Mode',
        'সহজ ও মৌলিক প্রশ্ন',
        green,
        'simple',
        Icons.star_rounded,
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Advance Mode')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            '9 SET QUESTION BANK',
            style: TextStyle(
              color: gold,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'আপনার প্রস্তুতি অনুযায়ী একটি Difficulty Mode বেছে নিন।',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 20),
          for (final mode in modes)
            Card(
              color: mode.$3.withOpacity(.15),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: Icon(
                  mode.$5,
                  color: mode.$3,
                  size: 36,
                ),
                title: Text(
                  mode.$1,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(mode.$2),
                trailing: const Icon(
                  Icons.arrow_forward_ios,
                  size: 17,
                ),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SetSelectionScreen(
                      difficulty: mode.$4,
                      title: mode.$1,
                    ),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: navy2,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Text(
              'প্রতিটি প্রশ্নের difficulty JSON ফাইলে নির্ধারণ করা থাকতে হবে। '
              'Hard, Easy ও Simple মোড সেই মান অনুযায়ী প্রশ্ন বাছাই করবে।',
              style: TextStyle(
                color: Colors.white70,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SetSelectionScreen extends StatelessWidget {
  final String difficulty;
  final String title;

  const SetSelectionScreen({
    super.key,
    required this.difficulty,
    required this.title,
  });

  Future<void> startSet(
    BuildContext context,
    int setNumber,
  ) async {
    try {
      final all = await QuestionBank.load(2012);

      if (!context.mounted) return;

      final filtered = all.where(
        (question) =>
            question.difficulty.toLowerCase() ==
            difficulty.toLowerCase(),
      ).toList();

      if (filtered.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '$title-এ কোনো প্রশ্ন পাওয়া যায়নি। '
              'questions_2012.json-এর difficulty যাচাই করুন।',
            ),
          ),
        );
        return;
      }

      // Set অনুযায়ী আলাদা প্রশ্ন নির্বাচন।
      final start = ((setNumber - 1) * 30) % filtered.length;

      final rotated = [
        ...filtered.skip(start),
        ...filtered.take(start),
      ];

      final selected = rotated.take(30).toList();

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ExamScreen(
            year: 2012,
            questions: selected,
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('প্রশ্ন লোড করা যায়নি: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = difficulty == 'hard'
        ? red
        : difficulty == 'easy'
            ? blue
            : green;

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (int i = 1; i <= 3; i++)
            Card(
              color: navy2,
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: CircleAvatar(
                  backgroundColor: color.withOpacity(.2),
                  child: Text(
                    '$i',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text('Set $i'),
                subtitle: const Text('সর্বোচ্চ ৩০টি প্রশ্ন'),
                trailing: const Icon(
                  Icons.play_arrow,
                  color: gold,
                ),
                onTap: () => startSet(context, i),
              ),
            ),
        ],
      ),
    );
  }
}

class FutureScreen extends StatelessWidget {
  const FutureScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final features = [
      'ঐতিহাসিক MCQ-এর Pattern Analysis',
      'আইন ও বিষয়ভিত্তিক প্রশ্ন বাছাই',
      'কঠিনতা অনুযায়ী অনুশীলন',
      'নতুন Practice MCQ ও উত্তর যাচাই',
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('2027 MCQ Mode'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF30206C),
                  Color(0xFF12518D),
                ],
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: purple),
            ),
            child: const Column(
              children: [
                Icon(
                  Icons.psychology_alt_rounded,
                  size: 72,
                  color: gold,
                ),
                SizedBox(height: 14),
                Text(
                  'AI-ASSISTED MCQ PRACTICE',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Prepare for the next examination',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'PLANNED FEATURES',
            style: TextStyle(
              color: gold,
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          for (final feature in features)
            ListTile(
              leading: const Icon(
                Icons.check_circle,
                color: green,
              ),
              title: Text(feature),
            ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: navy2,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Text(
              'এই সংস্করণে AI সংযুক্ত নেই। ভবিষ্যতে AI API অথবা '
              'যাচাইকৃত প্রশ্নের ডেটাবেস যুক্ত করে এই মোড চালু করতে হবে। '
              'আইন পরিবর্তিত হলে প্রশ্ন ও উত্তরও যাচাই করা জরুরি।',
              style: TextStyle(
                color: Colors.white70,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
