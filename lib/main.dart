import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:logger/src/logger.dart' as logger;

import 'audio_wave.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final AudioRecorderService _recorder = AudioRecorderService();
  //final AudioPlayerService _player = AudioPlayerService();

  @override
  void initState() {
    super.initState();
    _recorder.init();
    //_player.init();
  }

  @override
  void dispose() {
    //_player.dispose();
    _recorder.dispose();
    super.dispose();
  }

  bool _isBusy = false;
  void _toggleBusy({required bool value}) {
    setState(() {
      _isBusy = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: !_isBusy ? const Text('!!busy...') : const AudioWave(),
      ),
      floatingActionButton: GestureDetector(
        onLongPressStart: (details) async {
          _toggleBusy(value: true);
          await _recorder.record();
        },
        onLongPressEnd: (details) async {
          await _recorder.stop();
          _toggleBusy(value: true);

          final _p = AudioPlayerService();
          await _p.init();
          await _p.play(whenDone: () => _toggleBusy(value: false));
        },
        child: Container(
          width: 64.0,
          padding: const EdgeInsets.all(8.0),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.indigo,
          ),
          child: const Icon(
            Icons.mic,
            size: 42.0,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

late final String pathToSavedAudio;

class AudioRecorderService {
  FlutterSoundRecorder? _myRecorder;

  bool _isInitialised = false;
  bool get isRecording => _myRecorder!.isRecording;
  Future init() async {
    Directory tempDir = await getTemporaryDirectory();
    pathToSavedAudio = tempDir.path + '/audio_example.aac';
    _myRecorder = FlutterSoundRecorder(logLevel: logger.Level.nothing);

    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      throw RecordingPermissionException('Need the permission to record audio');
    }
    final storage = await Permission.storage.request();
    if (storage != PermissionStatus.granted) {
      throw RecordingPermissionException(
          'Need the permission to  await Permission.photos.request();');
    }
    _myRecorder = await _myRecorder!.openAudioSession();

    await _myRecorder!.setSubscriptionDuration(
      const Duration(milliseconds: 10),
    );
    _isInitialised = true;
  }

  Future record() async {
    if (_isInitialised) {
      await _myRecorder!.startRecorder(
        toFile: pathToSavedAudio,
        codec: Codec.aacMP4,
      );
    }
  }

  Future stop() async {
    if (_isInitialised) {
      final audio = await _myRecorder!.stopRecorder();
      print('audio: $audio');
    }
  }

  void dispose() {
    if (_isInitialised) {
      _myRecorder!.closeAudioSession();
      _myRecorder = null;
      _isInitialised = false;
    }
  }
}

class AudioPlayerService {
  late final FlutterSoundPlayer? _myPlayer;
  bool _isInitialised = false;

  bool get isPlaying => _myPlayer!.isPlaying;

  Future init() async {
    _myPlayer = FlutterSoundPlayer(logLevel: logger.Level.nothing);
    await _myPlayer!.openAudioSession();
    _isInitialised = true;
  }

  Future play({required Function whenDone}) async {
    // final bytes = File(pathToSavedAudio).readAsBytesSync();
    // final audioBaseString = base64Encode((bytes));
    if (_isInitialised) {
      await _myPlayer!.startPlayer(
        fromURI: pathToSavedAudio,
        //fromDataBuffer: base64.decode(audioBaseString),
        whenFinished: () async {
          // ignore: avoid_print
          print('Playing Audio Finnish');
          whenDone();
        },
      );
    }
  }

  Future playBytes({required Function whenDone}) async {
    final bytes = File(pathToSavedAudio).readAsBytesSync();
    print('bytes: $bytes');
    await _myPlayer!.startPlayer(
      fromDataBuffer: bytes,
      whenFinished: () async {
        whenDone();
        //File(pathToSavedAudio).deleteSync(recursive: true);
        await stop();
      },
    );
  }

  Future stop() async {
    if (_isInitialised) {
      await _myPlayer!.stopPlayer();
    }
  }

  void dispose() {
    if (_isInitialised) {
      _myPlayer!.closeAudioSession();
      _myPlayer = null;
      _isInitialised = false;
    }
  }
}
