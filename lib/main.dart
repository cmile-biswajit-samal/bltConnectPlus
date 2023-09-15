import 'dart:io';

import 'package:cron/cron.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import 'bluetooth_provider.dart';

void main() {
  if (Platform.isAndroid) {
    WidgetsFlutterBinding.ensureInitialized();
    [
      Permission.location,
      Permission.locationAlways,
      Permission.storage,
      Permission.bluetooth,
      Permission.bluetoothConnect,
      Permission.bluetoothScan
    ].request().then((status) {
      runApp(const MyApp());
    });
  } else {
    runApp(const MyApp());
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<BluetoothProvider>(
          create: (context) => BluetoothProvider(),
        ),
      ],
      child: MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: const MyHomePage(),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with WidgetsBindingObserver {
  late BluetoothProvider bluetoothProvider;

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    var cron = Cron();
    switch (state) {
      case AppLifecycleState.resumed:
        print('Resumed');
        cron.close();
        break;
      case AppLifecycleState.inactive:
        print('Inactive');
        break;
      case AppLifecycleState.paused:
        print('Paused');
        cron.schedule(Schedule.parse('*/10 * * * * *'), () async {
          if (FlutterBluePlus.isScanningNow == false && bluetoothProvider.currentDevice != null) {
            print('called cron part\n${bluetoothProvider.currentDevice}\n${bluetoothProvider.isConnected}\n${FlutterBluePlus.isScanningNow}');
            if(bluetoothProvider.isConnected == false){
              await bluetoothProvider.connectDevice();
            }else {
              bluetoothProvider.readData();
            }
          }
        });
        break;
      case AppLifecycleState.detached:
        print('Detached');
        break;
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance!.addObserver(this);
    initmethod();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    WidgetsBinding.instance!.removeObserver(this);
    print('Called Disposed');
    super.dispose();
  }

  initmethod() async {
    bluetoothProvider = Provider.of<BluetoothProvider>(context, listen: false);
    // await initializeProvider();
    // FlutterBluePlus.setLogLevel(LogLevel.verbose, color:false);
    await bluetoothProvider.checkBluetoothStatus();
  }

  // Future initializeProvider() async{
  //   WidgetsBinding.instance.addPostFrameCallback((_) {
  //
  //     // print('print state${bluetoothProvider.adapterState}');
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    return Consumer<BluetoothProvider>(
      builder: (BuildContext context, value, Widget? child) {
        return Scaffold(
          appBar: AppBar(
            backgroundColor: Theme.of(context).colorScheme.inversePrimary,
            title: Text("HomeScreen"),
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                Center(
                    child: Container(
                  child: Text("Scanned Data"),
                )),
                const SizedBox(),
                Container(
                  child: Text("\n${value.seen}\n"),
                ),
              ],
            ),
          ),
          floatingActionButton: Container(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                FloatingActionButton(
                  onPressed: () => bluetoothProvider.scanMethod(),
                  tooltip: 'Scan',
                  child: const Icon(Icons.bluetooth),
                ),
                FloatingActionButton(
                  onPressed: () async=>await bluetoothProvider.connectDevice(),
                  tooltip: 'Connect',
                  child: const Icon(Icons.bluetooth_connected_sharp),
                ),
                FloatingActionButton(
                  onPressed: () async=>await bluetoothProvider.disconnectDevice(),
                  tooltip: 'Disconnect',
                  child: const Icon(Icons.bluetooth_disabled),
                ),
                value.isConnected ? ElevatedButton(
                    onPressed: ()async{ await bluetoothProvider.readData();},
                    child: Text("Read Data"))
                    :ElevatedButton(
                    onPressed: () async {
                      await bluetoothProvider.connectDevice();
                    },
                    child: Text("connect"))
              ],
            ),
          ), // This trailing comma makes auto-formatting nicer for build methods.
        );
      },
    );
  }
}
