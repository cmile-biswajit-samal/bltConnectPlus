import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BluetoothProvider extends ChangeNotifier {
  late BluetoothAdapterState? adapterState;
  BluetoothDevice? currentDevice;
  Set<BluetoothDevice> seen = {};
  bool isConnected = false;
  bool connecting = false;

  checkBluetoothStatus() async {
    ///check for device bluetooth supported or not
    if (await FlutterBluePlus.isAvailable == false) {
      print("Bluetooth not supported by this device");
      return;
    } else {
      await FlutterBluePlus.turnOn();
      adapterState = await FlutterBluePlus.adapterState.first;
    }
  }

  scanMethod() async {
    try {
      FlutterBluePlus.scanResults.listen(
        (results) async {
          seen.clear();
          for (ScanResult r in results) {
            if (seen.contains(r.device.remoteId) == false) {
              if (r.device.remoteId.str == "48:23:35:03:4F:6E") {
                seen.add(r.device);
                currentDevice = r.device;
               // await saveDeviceToPrefs(r.device);
               notifyListeners();
              }
              notifyListeners();
            }
          }
        },
      );
      debugPrint('----Data-${seen}');
      // seen.map((e) => e.remoteId.str == "AC:98:B1:11:1D:C6" );
      await FlutterBluePlus.startScan(
          timeout: const Duration(seconds: 10), androidUsesFineLocation: false);
    } catch (e) {
      print('Scan Error==>$e');
    }
  }

  connectDevice() async {
    print('called to connect $currentDevice');
    // currentDevice =  await getDeviceFromPrefs();
    if (currentDevice == null) {
      List<BluetoothDevice>  bondedDevices =
          await FlutterBluePlus.bondedDevices;

      for (var d in bondedDevices) {
        print('---------$d');
        if (d.remoteId.str == "48:23:35:03:4F:6E") {
          currentDevice = d;
          print('called to connect==222222 $currentDevice');
        }
      }
    }
    if (currentDevice != null) {
          connecting = true;
          notifyListeners();
       try{
         currentDevice
             ?.connect(timeout: const Duration(minutes: 10));
       }catch(error){
         connecting = false;
         print('=====?>>>$error');
      }

        currentDevice?.connectionState
            .listen((BluetoothConnectionState state) async {

          if (state == BluetoothConnectionState.disconnected) {
            print('====device is disconnected====');
            isConnected = false;
            connecting = false;
            notifyListeners();
          }else if(state == BluetoothConnectionState.connected) {
            print('====device is connected=====');
            isConnected = true;
            notifyListeners();
          }
        });
    }
  }

  disconnectDevice() async {
    try {
      if (currentDevice == null) {
        List<BluetoothDevice> connectedSystemDevices =
            await FlutterBluePlus.connectedSystemDevices;
        for (var d in connectedSystemDevices) {
          if (d.remoteId.str == "48:23:35:03:4F:6E") {
            currentDevice = d;
          }
        }
      }
      await currentDevice?.disconnect();
      print('disconnect successful');
    } catch (e) {
      print('disconnect error');
    }
  }

  readData() async {
    print(
        'called read more$currentDevice\n\n==${await FlutterBluePlus.bondedDevices}');
    await FlutterBluePlus.stopScan();
    try {
      // Loop through discovered services
      List<BluetoothService> services = await currentDevice!.discoverServices();
      services.forEach((service) {
        // Check if this is the service you're interested in
        print('each service$service');
        if (service.uuid.toString() == '00002a00-0000-1000-8000-00805f9b34fb') {
          // Loop through characteristics in the service
          service.characteristics.forEach((c) async{
            List<int> value = await c.read();
            print('read values${value}');
            c.onValueReceived.listen((value) {
              print('onValueReceived${value}');
            });
            // Subscribe to characteristic notifications
            // characteristic.setNotifyValue(true).then((_) {
            //   characteristic.onValueReceived.listen((data) {
            //     // Handle data received from the characteristic
            //     print('Received data: ${data}');
            //   });
            // });

          });
        }
      });
      // });
    } catch (e) {
      print('Error print$e');
    }
  }

  callWhenDeactive(){

  }

  Future<void> saveDeviceToPrefs(BluetoothDevice currentDevice) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'DEVICE_DATA'; // Replace with a unique key for your object

    // Convert the object to a JSON string
    final jsonString = jsonEncode(currentDevice.toString());

    // Save the JSON string to shared preferences
    prefs.setString(key, jsonString);
    print('==== id ${prefs.getString(key) ?? ""}');
  }

  // Future<dynamic> getDeviceFromPrefs() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   final key = 'DEVICE_DATA';
  //   final jsonString = prefs.getString(key) ?? "";
  //   currentDevice = jsonDecode(jsonString);
  //   return currentDevice;
  // }

}
