import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'package:flutter/material.dart';
import 'package:rsdk_flutter/backgroundview.dart';
import 'package:rsdk_flutter/levelview.dart';
import 'package:rsdk_flutter/models/gamestage.dart';
import 'models/gameconfig.dart';
import 'models/stages/stage.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RSDK Editor',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: const MainView(title: 'RSDK Editor'),
    );
  }
}

class MainView extends StatefulWidget {
  const MainView({Key? key, required this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MainView> createState() => _MainViewState();
}

enum _ViewType { layout, background, objects, chunks }

class _MainViewState extends State<MainView> {
  GameConfigV4? _gameConfig;
  String dataPath = "";
  GameStage? _selectedGameStage;
  Stage? _selectedStage;
  _ViewType _viewType = _ViewType.layout;

  set viewType(_ViewType value) => setState(() => _viewType = value);

  Future<void> showError(String msg) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Error"),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(msg),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _openRsdkGame() async {

    dataPath = rootPath;
    final gameConfigFile = File(path.join(dataPath, "Game/GameConfig.bin"));
    if (!await gameConfigFile.exists()) {
      await showError("Not a valid RSDK Data folder");
      return;
    }

    await readGameConfig(gameConfigFile);
  }

  void _closeRsdkGame() => setState(() {
      _gameConfig = null;
      _selectedGameStage = null;
      _selectedStage = null;
    });

  Future<void> readGameConfig(File file) async {
    final gameConfig = GameConfigV4(file);
    await gameConfig.read();

    setState(() {
      _gameConfig = gameConfig;
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      drawer: Drawer(
        child: ListView(
          children: _buildDrawerMenu(),
        ),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: _buildView(context),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await _openRsdkGame();
          _setSelectedStage(_gameConfig!.stagesRegular[0]);
        },
        tooltip: 'For debugging purposes',
        child: const Icon(Icons.bug_report_outlined),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  List<Widget> _buildDrawerMenu() {
    final defaultControls = [
      ListTile(
          title: const Text("Open game"),
          leading: const Icon(Icons.folder_open),
          onTap: _openRsdkGame),
      ListTile(
          title: const Text('Close game'),
          leading: const Icon(Icons.bug_report),
          onTap: _closeRsdkGame),
      ListTile(
          title: const Text('Settings'),
          leading: const Icon(Icons.settings),
          enabled: false,
          onTap: _showSettings),
    ];

    final headerControls = [
      DrawerHeader(
          decoration: const BoxDecoration(
            color: Colors.blue,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _gameConfig?.name ?? "No RSDK loaded",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
              _buildStageNameTitle()
            ],
          )),
    ];

    final gameControls = _gameConfig != null
        ? [
      ExpansionTile(
          title: const Text("Presentation stages"),
          leading: const Icon(Icons.aspect_ratio),
          trailing: const Icon(Icons.arrow_drop_down),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          children: _showPresentationStages()),
      ExpansionTile(
          title: const Text("Regular stages"),
          leading: const Icon(Icons.aspect_ratio),
          trailing: const Icon(Icons.arrow_drop_down),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          children: _showRegularStages()),
      ExpansionTile(
          title: const Text("Special stages"),
          leading: const Icon(Icons.aspect_ratio),
          trailing: const Icon(Icons.arrow_drop_down),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          children: _showSpecialStages()),
      ExpansionTile(
          title: const Text("Bonus stages"),
          leading: const Icon(Icons.aspect_ratio),
          trailing: const Icon(Icons.arrow_drop_down),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          children: _showBonusStages()),
      const Divider(height: 20),
      ListTile(
                title: const Text("Global objects"),
          leading: const Icon(Icons.auto_awesome_motion),
          enabled: false,
          onTap: _showGameObjects),
      ListTile(
          title: const Text("Variables"),
          leading: const Icon(Icons.auto_awesome),
          enabled: false,
          onTap: _showGameVariables),
      ListTile(
          title: const Text("Sound effects"),
          leading: const Icon(Icons.volume_up),
          enabled: false,
          onTap: _showGameSoundEffects),
      ListTile(
          title: const Text("Players"),
          leading: const Icon(Icons.contact_page),
          enabled: false,
          onTap: _showGamePlayers),
      ListTile(
          title: const Text("Animations"),
          leading: const Icon(Icons.burst_mode),
          enabled: false,
          onTap: _showAnimations),
      const Divider(height: 20),
          ]
        : List<Widget>.empty();

    final stageControls = _selectedGameStage != null
        ? [
      ListTile(
          title: const Text("Layout"),
          leading: const Icon(Icons.grid_on),
                selected: _viewType == _ViewType.layout,
          onTap: _showStageLayout),
      ListTile(
          title: const Text("Background"),
          leading: const Icon(Icons.landscape),
                selected: _viewType == _ViewType.background,
          onTap: _showStageBackground),
      ListTile(
          title: const Text("Objects"),
          leading: const Icon(Icons.library_books),
                selected: _viewType == _ViewType.objects,
          enabled: false,
          onTap: _showStageObjects),
      ListTile(
          title: const Text("Chunks"),
          leading: const Icon(Icons.grid_view),
                selected: _viewType == _ViewType.chunks,
          enabled: false,
          onTap: _showStageChunks),
      const Divider(height: 20),
          ]
        : List<Widget>.empty();

    return [headerControls, stageControls, gameControls, defaultControls]
        .expand((element) => element)
        .toList();
  }

  Widget _buildStageNameTitle() => _selectedGameStage == null
      ? const SizedBox.shrink()
      : Text(_selectedGameStage!.name);

  List<Widget> _buildStageNames(List<GameStage> stages) => stages
      .map((stage) => ListTile(
          title: Text(stage.name), onTap: () => _setSelectedStage(stage)))
      .toList();

  Widget _buildView(BuildContext context) {
    if (_gameConfig == null) {
      return const Text("Welcome to RSDK Editor!",
          style: TextStyle(fontSize: 20));
    }
    
    if (_selectedGameStage == null) {
      return const Text("Select a stage or any game settings to start.",
          style: TextStyle(fontSize: 20));
    }

    switch (_viewType) {
      case _ViewType.layout:
        return LevelView(key: UniqueKey(), stage: _selectedStage!);
      case _ViewType.background:
        return BackgroundView(key: UniqueKey(), stage: _selectedStage!);
      case _ViewType.objects:
        return const Text("objects");
      case _ViewType.chunks:
        return const Text("chunks");
    }
  }

  void _showStageLayout() => viewType = _ViewType.layout;

  void _showStageBackground() => viewType = _ViewType.background;

  void _showStageObjects() => viewType = _ViewType.objects;

  void _showStageChunks() => viewType = _ViewType.chunks;

  List<Widget> _showPresentationStages() =>
      _buildStageNames(_gameConfig!.stagesPresentation);

  List<Widget> _showRegularStages() =>
      _buildStageNames(_gameConfig!.stagesRegular);

  List<Widget> _showSpecialStages() =>
      _buildStageNames(_gameConfig!.stagesSpecial);

  List<Widget> _showBonusStages() => _buildStageNames(_gameConfig!.stagesBonus);

  void _showGameObjects() {}

  void _showGameVariables() {}

  void _showGameSoundEffects() {}

  void _showGamePlayers() {}

  void _showAnimations() {}

  void _showSettings() {}

  _setSelectedStage(GameStage gameStage) {
    var stage = Stage(dataPath, _gameConfig!, gameStage);
    return stage.load().whenComplete(() => {
          setState(() {
            _selectedGameStage = gameStage;
            _selectedStage = stage;
          })
        });
  }
}
