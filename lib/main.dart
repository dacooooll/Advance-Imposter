import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

// ============================================================================
// 1. ADVANCED DATA MODELS & ENGINE LOGIC CORE
// ============================================================================
enum PlayerRole { player, imposter }
enum TurnDirection { clockwise, counterClockwise, chaosRandom }
enum StartingPlayerRule { random, sequential, imposterStarts }

class Player {
  final String id;
  String name;                 
  PlayerRole role;
  String secretWord;
  String aiHintWord;          
  List<String> fellowImposters; 
  bool hasRevealedRole;        

  Player({
    required this.id,
    required this.name,
    this.role = PlayerRole.player,
    this.secretWord = '',
    this.aiHintWord = '',
    List<String>? fellowImposters,
    this.hasRevealedRole = false,
  }) : this.fellowImposters = fellowImposters ?? [];

  void resetRoundState() {
    role = PlayerRole.player;
    secretWord = '';
    aiHintWord = '';
    fellowImposters.clear();
    hasRevealedRole = false; 
  }
}

class GameEngine {
  List<Player> players = [];
  String currentSecretWord = '';
  String currentHintWord = '';
  String activatedCategory = '';
  
  int selectedTimerDuration = 10;
  TurnDirection chosenDirection = TurnDirection.clockwise;
  StartingPlayerRule chosenStartingRule = StartingPlayerRule.random;

  final Map<String, List<Map<String, String>>> _masterDatabase = {
    'Food 🍕': [{'word': 'Sushi', 'hint': 'Rice or Seafood'}, {'word': 'Taco', 'hint': 'Mexican or Shell'}, {'word': 'Croissant', 'hint': 'Bakery or French'}],
    'Animals 🦁': [{'word': 'Chameleon', 'hint': 'Lizard or Camouflage'}, {'word': 'Axolotl', 'hint': 'Water Salamander'}, {'word': 'Capybara', 'hint': 'Giant Rodent'}],
    'Movies 🎬': [{'word': 'Inception', 'hint': 'Dreams or Leonardo'}, {'word': 'Interstellar', 'hint': 'Space or Black Hole'}, {'word': 'Avatar', 'hint': 'Blue or Pandora'}],
    'Places 🌍': [{'word': 'Paris', 'hint': 'Eiffel Tower'}, {'word': 'Taj Mahal', 'hint': 'India or Marble'}, {'word': 'Tokyo', 'hint': 'Japan or Neon'}],
    'Objects 🎸': [{'word': 'Guitar', 'hint': 'Strings or Music'}, {'word': 'Smartphone', 'hint': 'Screen or Pocket'}, {'word': 'Telescope', 'hint': 'Stars or Lens'}],
    'Pop Culture 🦸‍♂️': [{'word': 'Batman', 'hint': 'Gotham or Cape'}, {'word': 'Anime', 'hint': 'Japan or Animation'}],
    'Gaming 🎮': [{'word': 'Minecraft', 'hint': 'Blocks or Mining'}, {'word': 'Mario', 'hint': 'Nintendo or Mustache'}],
    'Sports ⚽': [{'word': 'Cricket', 'hint': 'Bat or Wicket'}, {'word': 'F1 Racing', 'hint': 'Fast or Track'}],
    'College Life 📚': [{'word': 'Lecture', 'hint': 'Professor or Sleep'}, {'word': 'Hostel Chai', 'hint': 'Late Night Drink'}],
    'Spicy/Adult 🔥': [{'word': 'Gossip', 'hint': 'Secrets or Whispers'}, {'word': 'Dark Humor', 'hint': 'Edgy Jokes'}],
  };

  void initializeEngine(int total, List<String> customNames, int imposterCount, List<String> activeCategories) {
    players.clear();
    for (int i = 0; i < total; i++) {
      String assignedName = (i < customNames.length && customNames[i].trim().isNotEmpty) ? customNames[i] : 'Friend ${i + 1}';
      players.add(Player(id: 'P_$i', name: assignedName));
    }

    final random = Random();
    List<String> safeCategories = List.from(activeCategories);
    if (safeCategories.isEmpty) safeCategories.add('Food 🍕');
    activatedCategory = safeCategories[random.nextInt(safeCategories.length)];
    
    final categoryPool = _masterDatabase[activatedCategory] ?? _masterDatabase['Food 🍕']!;
    final selectedPair = categoryPool[random.nextInt(categoryPool.length)];
    currentSecretWord = selectedPair['word']!;
    currentHintWord = selectedPair['hint']!;

    for (var player in players) {
      player.resetRoundState();
      player.secretWord = currentSecretWord;
    }

    int assigned = 0;
    List<Player> imposterList = [];
    while (assigned < imposterCount) {
      int idx = random.nextInt(players.length);
      if (players[idx].role != PlayerRole.imposter) {
        players[idx].role = PlayerRole.imposter;
        players[idx].secretWord = 'IMPOSTER';
        imposterList.add(players[idx]);
        assigned++;
      }
    }

    List<String> imposterNames = imposterList.map((imp) => imp.name).toList();
    for (var imp in imposterList) {
      imp.aiHintWord = currentHintWord;
      imp.fellowImposters = imposterNames.where((name) => name != imp.name).toList();
    }
  }

  String calculateStartingPlayer() {
    try {
      if (chosenStartingRule == StartingPlayerRule.imposterStarts) {
        return players.firstWhere((p) => p.role == PlayerRole.imposter).name;
      } else if (chosenStartingRule == StartingPlayerRule.sequential) {
        return players[0].name;
      }
    } catch (_) {}
    final random = Random();
    return players[random.nextInt(players.length)].name;
  }
}

final GameEngine globalEngine = GameEngine();

// ============================================================================
// 2. ENTRY HUB POINTER
// ============================================================================
void main() => runApp(const AdvancedImposterApp());

class AdvancedImposterApp extends StatelessWidget {
  const AdvancedImposterApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Imposter Advanced',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.deepPurple,
        scaffoldBackgroundColor: const Color(0xFF121212),
        colorScheme: const ColorScheme.dark(
          primary: Colors.deepPurpleAccent, 
          secondary: Colors.tealAccent, 
          surface: Color(0xFF1E1E1E)
        ),
      ),
      home: const LobbySetupScreen(),
    );
  }
}

// ============================================================================
// 3. UI SCREEN: ADVANCED MASTER LOBBY
// ============================================================================
class LobbySetupScreen extends StatefulWidget {
  const LobbySetupScreen({Key? key}) : super(key: key);

  @override
  State<LobbySetupScreen> createState() => _LobbySetupScreenState();
}

class _LobbySetupScreenState extends State<LobbySetupScreen> {
  double _totalPlayers = 6;
  double _imposterCount = 1;
  double _viewTimerDuration = 10; 
  
  final List<String> _selectedCategories = ['Food 🍕', 'Animals 🦁'];
  StartingPlayerRule _startingRule = StartingPlayerRule.random;
  TurnDirection _turnDirection = TurnDirection.clockwise;

  final List<String> _allCategories = ['Food 🍕', 'Animals 🦁', 'Movies 🎬', 'Places 🌍', 'Objects 🎸', 'Pop Culture 🦸‍♂️', 'Gaming 🎮', 'Sports ⚽', 'College Life 📚', 'Spicy/Adult 🔥'];
  final List<TextEditingController> _nameControllers = [];

  @override
  void initState() {
    super.initState();
    _updateControllers();
  }

  void _updateControllers() {
    int currentLen = _nameControllers.length;
    int targetLen = _totalPlayers.toInt();
    if (currentLen < targetLen) {
      for (int i = currentLen; i < targetLen; i++) {
        _nameControllers.add(TextEditingController(text: 'Friend ${i + 1}'));
      }
    } else if (currentLen > targetLen) {
      for (int i = currentLen - 1; i >= targetLen; i--) {
        _nameControllers[i].dispose();
        _nameControllers.removeAt(i);
      }
    }
  }

  @override
  void dispose() {
    for (var c in _nameControllers) { c.dispose(); }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _updateControllers();
    double maxImpostersAllowed = max(1.0, _totalPlayers - 1);
    if (_imposterCount > maxImpostersAllowed) _imposterCount = maxImpostersAllowed;

    return Scaffold(
      appBar: AppBar(title: const Text('🕵️‍♂️ LOBBY HOST SETTINGS'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select Category Matrix (Multi-Select Allowed!)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.tealAccent)),
            const SizedBox(height: 8),
            Container(
              height: 140,
              decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(12)),
              child: ListView.builder(
                itemCount: _allCategories.length,
                itemBuilder: (context, idx) {
                  final cat = _allCategories[idx];
                  final isChecked = _selectedCategories.contains(cat);
                  return CheckboxListTile(
                    title: Text(cat, style: const TextStyle(fontSize: 14)),
                    value: isChecked,
                    activeColor: Colors.deepPurpleAccent,
                    onChanged: (bool? val) {
                      setState(() {
                        if (val == true) { _selectedCategories.add(cat); } 
                        else { if (_selectedCategories.length > 1) _selectedCategories.remove(cat); }
                      });
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            const Text('Advanced Custom Game Mechanics', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.tealAccent)),
            const SizedBox(height: 8),
            DropdownButtonFormField<StartingPlayerRule>(
              value: _startingRule,
              decoration: const InputDecoration(labelText: 'Who Begins the Discussion?'),
              items: const [
                DropdownMenuItem(value: StartingPlayerRule.random, child: Text('Random Selection')),
                DropdownMenuItem(value: StartingPlayerRule.sequential, child: Text('Friend Slot 1 Starts')),
                DropdownMenuItem(value: StartingPlayerRule.imposterStarts, child: Text('Force An Imposter to Speak First ⚠️')),
              ],
              onChanged: (val) { if (val != null) setState(() { _startingRule = val; }); },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<TurnDirection>(
              value: _turnDirection,
              decoration: const InputDecoration(labelText: 'Discussion Circular Rotation Direction'),
              items: const [
                DropdownMenuItem(value: TurnDirection.clockwise, child: Text('Clockwise Flow ➡️')),
                DropdownMenuItem(value: TurnDirection.counterClockwise, child: Text('Counter-Clockwise Flow ⬅️')),
                DropdownMenuItem(value: TurnDirection.chaosRandom, child: Text('💥 Absolute Chaos Random Order')),
              ],
              onChanged: (val) { if (val != null) setState(() { _turnDirection = val; }); },
            ),
            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Card Peek Reveal Window Timer:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                Text('${_viewTimerDuration.toInt()} Seconds', style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
              ],
            ),
            Slider(
              value: _viewTimerDuration,
              min: 5,
              max: 30,
              divisions: 5,
              activeColor: Colors.amber,
              onChanged: (val) { setState(() { _viewTimerDuration = val; }); },
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Friends Joining (Max 100):', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                Text('${_totalPlayers.toInt()} Players', style: const TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold)),
              ],
            ),
            Slider(
              value: _totalPlayers,
              min: 3,
              max: 100,
              divisions: 97,
              onChanged: (val) { setState(() { _totalPlayers = val; }); },
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Hidden Imposters Setting:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                Text('${_imposterCount.toInt()} Imposters', style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
              ],
            ),
            Slider(
              value: _imposterCount,
              min: 1,
              max: maxImpostersAllowed,
              divisions: maxImpostersAllowed.toInt() > 0 ? maxImpostersAllowed.toInt() : 1,
              activeColor: Colors.redAccent,
              onChanged: (val) { setState(() { _imposterCount = val; }); },
            ),

            const SizedBox(height: 12),
            Container(
              height: 140,
              decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(12)),
              child: ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: _totalPlayers.toInt(),
                itemBuilder: (context, index) {
                  return Row(
                    children: [
                      CircleAvatar(radius: 11, child: Text('${index + 1}', style: const TextStyle(fontSize: 10))),
                      const SizedBox(width: 12),
                      Expanded(child: TextField(controller: _nameControllers[index], decoration: const InputDecoration(isDense: true, hintText: 'Enter custom name'))),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary),
                onPressed: () {
                  final names = _nameControllers.map((c) => c.text).toList();
                  
                  globalEngine.selectedTimerDuration = _viewTimerDuration.toInt();
                  globalEngine.chosenDirection = _turnDirection;
                  globalEngine.chosenStartingRule = _startingRule;
                  
                  globalEngine.initializeEngine(_totalPlayers.toInt(), names, _imposterCount.toInt(), _selectedCategories);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const CentralSelectionHubScreen()));
                },
                child: const Text('GENERATE DECENTRALIZED HUB', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 4. UI SCREEN: ROLE DECENTRALIZED REVEAL HUB
// ============================================================================
class CentralSelectionHubScreen extends StatefulWidget {
  const CentralSelectionHubScreen({Key? key}) : super(key: key);

  @override
  State<CentralSelectionHubScreen> createState() => _CentralSelectionHubScreenState();
}

class _CentralSelectionHubScreenState extends State<CentralSelectionHubScreen> {
  @override
  Widget build(BuildContext context) {
    bool isRevealPhaseFinished = globalEngine.players.every((p) => p.hasRevealedRole);

    return Scaffold(
      appBar: AppBar(title: const Text('🎛️ CENTRAL PASS DEVICE HUB'), automaticallyImplyLeading: false),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              width: double.infinity,
              decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.blueAccent)),
              child: Text('Category chosen dynamically: [ ${globalEngine.activatedCategory} ]', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent)),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 2.3),
                itemCount: globalEngine.players.length,
                itemBuilder: (context, index) {
                  final player = globalEngine.players[index];
                  return ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: player.hasRevealedRole ? Colors.grey.withOpacity(0.05) : Theme.of(context).colorScheme.surface,
                    ),
                    onPressed: player.hasRevealedRole ? null : () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => IndividualSecurityRevealScreen(
                        player: player,
                        countdownDuration: globalEngine.selectedTimerDuration,
                      ))).then((_) => setState(() {}));
                    },
                    child: Text(
                      player.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold, 
                        color: player.hasRevealedRole ? Colors.grey : Colors.white,
                        decoration: player.hasRevealedRole ? TextDecoration.lineThrough : TextDecoration.none
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: isRevealPhaseFinished ? Colors.green : Colors.grey.shade900),
                onPressed: isRevealPhaseFinished ? () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const RoundDiscussionBoardScreen()));
                } : null,
                child: Text(isRevealPhaseFinished ? '📢 PROCEED TO DISCUSSION BOARD' : '🔒 LOCK ACTION: PEEK PENDING'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 5. UI SCREEN: DISCUSSION BOARD WITH GENUINE RULEBOOK
// ============================================================================
class RoundDiscussionBoardScreen extends StatefulWidget {
  const RoundDiscussionBoardScreen({Key? key}) : super(key: key);

  @override
  State<RoundDiscussionBoardScreen> createState() => _RoundDiscussionBoardScreenState();
}

class _RoundDiscussionBoardScreenState extends State<RoundDiscussionBoardScreen> {
  String _startingSpeaker = '';
  String _directionExplanation = '';

  @override
  void initState() {
    super.initState();
    _startingSpeaker = globalEngine.calculateStartingPlayer();
    
    if (globalEngine.chosenDirection == TurnDirection.clockwise) {
      _directionExplanation = 'CLOCKWISE FLOW ➡️ (Pass turn to the right)';
    } else if (globalEngine.chosenDirection == TurnDirection.counterClockwise) {
      _directionExplanation = 'COUNTER-CLOCKWISE FLOW ⬅️ (Pass turn to the left)';
    } else {
      _directionExplanation = '💥 TOTAL ANARCHY (App displays who speaks next out of nowhere!)';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('📢 GROUP DISCUSSION ROOM'), automaticallyImplyLeading: false),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              color: Colors.deepPurple.withOpacity(0.2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Colors.deepPurpleAccent)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text('🏁 CHOSEN GAME START Pointers:', style: TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.record_voice_over, color: Colors.tealAccent),
                        const SizedBox(width: 8),
                        Text('First Speaker: $_startingSpeaker', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.tealAccent)),
                      ],
                    ),
                    const Divider(height: 20, color: Colors.deepPurpleAccent),
                    Text('🔄 Rotation Order: $_directionExplanation', textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            const Text('📋 GENUINE RULES OF ENGAGEMENT:', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.amber)),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFF161616), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade800)),
                child: ListView(
                  children: const [
                    ListTile(
                      leading: Icon(Icons.looks_one, color: Colors.amber),
                      title: Text('Give Exactly One Clue', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      subtitle: Text('Going around the circle, state exactly one safe context clue. Do not explicitly say the secret word itself!'),
                    ),
                    ListTile(
                      leading: Icon(Icons.looks_two, color: Colors.amber),
                      title: Text('The Imposter\'s Strategy', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      subtitle: Text('Listen carefully to what others say, use your category topic tag, and drop matching bluffs to blend right in.'),
                    ),
                    ListTile(
                      leading: Icon(Icons.forum, color: Colors.tealAccent),
                      title: Text('Real-Life Physical Voting', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      subtitle: Text('Argue, debate, and accuse right there in your real-world circle! Once your group reaches a final verdict and points out the primary suspect, tap the button below to see the truth.'),
                    ),
                    ListTile(
                      leading: Icon(Icons.psychology, color: Colors.redAccent), 
                      title: Text('⚠️ Sudden Death Win-Steal Rule', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.redAccent)),
                      subtitle: Text('If the group successfully catches an Imposter, that caught player gets one final chance to state the Citizens\' secret word aloud. If they guess correctly, they instantly steal the win!'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const GrandImposterRevealScreen()));
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.visibility, color: Colors.white),
                    SizedBox(width: 8),
                    Text('REVEAL ALL IMPOSTERS TRUTH', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 6. UI SCREEN: THE GRAND REVEAL SCREEN
// ============================================================================
class GrandImposterRevealScreen extends StatelessWidget {
  const GrandImposterRevealScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final imposters = globalEngine.players.where((p) => p.role == PlayerRole.imposter).toList();
    final citizens = globalEngine.players.where((p) => p.role != PlayerRole.imposter).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('🔍 THE TRUTH EXPOSED'), automaticallyImplyLeading: false),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              width: double.infinity,
              decoration: BoxDecoration(color: Colors.amber.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.amber)),
              child: Column(
                children: [
                  const Text('THE SECRET WORD WAS:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.amber)),
                  const SizedBox(height: 4),
                  Text('"${globalEngine.currentSecretWord}"', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 4),
                  Text('Category Topic: [ ${globalEngine.activatedCategory} ]', style: const TextStyle(fontSize: 13, color: Colors.grey)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            const Text('🔴 THE HIDDEN IMPOSTERS:', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.redAccent)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              width: double.infinity,
              decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(12)),
              child: Text(
                imposters.map((p) => p.name).join(', '),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
            const SizedBox(height: 16),

            const Text('🟢 INNOCENT CITIZENS:', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.tealAccent)),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                width: double.infinity,
                decoration: BoxDecoration(color: const Color(0xFF161616), borderRadius: BorderRadius.circular(12)),
                child: ListView(
                  children: [
                    Text(
                      citizens.map((p) => p.name).join(', '),
                      style: const TextStyle(fontSize: 14, color: Colors.grey, height: 1.4),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary),
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: const Text('START NEXT ROUND 🔄', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 7. UI SCREEN: TIMED VERIFICATION VIEW
// ============================================================================
class IndividualSecurityRevealScreen extends StatefulWidget {
  final Player player;
  final int countdownDuration;
  
  const IndividualSecurityRevealScreen({Key? key, required this.player, required this.countdownDuration}) : super(key: key);

  @override
  State<IndividualSecurityRevealScreen> createState() => _IndividualSecurityRevealScreenState();
}

class _IndividualSecurityRevealScreenState extends State<IndividualSecurityRevealScreen> {
  bool _identityUnlocked = false;
  int _secondsRemaining = 0;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _secondsRemaining = widget.countdownDuration;
  }

  void _startSecurityCountdown() {
    setState(() { _identityUnlocked = true; });
    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 1) {
        setState(() { _secondsRemaining--; });
      } else {
        _ticker?.cancel();
        widget.player.hasRevealedRole = true;
        Navigator.pop(context); 
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('🔒 SECURITY GATE: ${widget.player.name.toUpperCase()}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.amber)),
              const SizedBox(height: 8),
              if (!_identityUnlocked) ...[
                const Text('Confirm your friends aren\'t peeking before unlocking.', style: TextStyle(color: Colors.grey, fontSize: 12)),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  height: 140,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                    onPressed: _startSecurityCountdown,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.lock_open, size: 36),
                        SizedBox(height: 8),
                        Text('REVEAL IDENTITY CARD', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
              ] else ...[
                Text('⏳ CLEAR CARD SHUTDOWN IN: $_secondsRemaining SECONDS', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent)),
                const SizedBox(height: 24),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: const Color(0xFF161616), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.tealAccent.withOpacity(0.2))),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('CATEGORY MATRIX TOPIC: [ ${globalEngine.activatedCategory} ]', textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 20),
                        
                        if (widget.player.role == PlayerRole.player) ...[
                          const Text('🟢 INNOCENT CITIZEN', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.tealAccent, fontSize: 18)),
                          const SizedBox(height: 16),
                          const Text('Your Secret Keyword:', style: TextStyle(color: Colors.grey, fontSize: 12)),
                          const SizedBox(height: 4),
                          Text('"${widget.player.secretWord}"', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                        ] else ...[
                          const Text('⚠️ WARNING: YOU ARE THE IMPOSTER ⚠️', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent, fontSize: 16)),
                          const SizedBox(height: 16),
                          Text('🕵️‍♂️ Allied Accomplices: ${widget.player.fellowImposters.isEmpty ? "None (Solo)" : widget.player.fellowImposters.join(", ")}'),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                            child: Text('AI First-Round Bluff Hint: [ ${widget.player.aiHintWord} ]', style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
