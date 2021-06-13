// For performing some operations asynchronously
import 'dart:async';
import 'dart:convert';

// For using PlatformException
import 'package:flutter/services.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmartHome',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: BluetoothApp(),
    );
  }
}

class BluetoothApp extends StatefulWidget {
  @override
  _BluetoothAppState createState() => _BluetoothAppState();
}

class _BluetoothAppState extends State<BluetoothApp> {
  // Initializing the Bluetooth connection state to be unknown
  BluetoothState _bluetoothState = BluetoothState.UNKNOWN;
  // Initializing a global key, as it would help us in showing a SnackBar later
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  // Get the instance of the Bluetooth
  FlutterBluetoothSerial _bluetooth = FlutterBluetoothSerial.instance;
  // Track the Bluetooth connection with the remote device
  BluetoothConnection connection;

  int _lightstate;
  int _deviceState;
  int _buzzstate;
  int _doorstate;

  bool isDisconnecting = false;


  // To track whether the device is still connected to Bluetooth
  bool get isConnected => connection != null && connection.isConnected;

  // Define some variables, which will be required later
  List<BluetoothDevice> _devicesList = [];
  BluetoothDevice _device;
  bool _connected = false;
  bool _isButtonUnavailable = false;

  @override
  void initState() {
    super.initState();

    // Get current state
    FlutterBluetoothSerial.instance.state.then((state) {
      setState(() {
        _bluetoothState = state;
      });
    });

    _lightstate = 0; // neutral
    _deviceState=0;
    _buzzstate=0;
    _doorstate=0;

    // If the bluetooth of the device is not enabled,
    // then request permission to turn on bluetooth
    // as the app starts up
    enableBluetooth();

    // Listen for further state changes
    FlutterBluetoothSerial.instance
        .onStateChanged()
        .listen((BluetoothState state) {
      setState(() {
        _bluetoothState = state;
        if (_bluetoothState == BluetoothState.STATE_OFF) {
          _isButtonUnavailable = true;
        }
        getPairedDevices();
      });
    });
  }

  @override
  void dispose() {
    // Avoid memory leak and disconnect
    if (isConnected) {
      isDisconnecting = true;
      connection.dispose();
      connection = null;
    }

    super.dispose();
  }

  // Request Bluetooth permission from the user
  Future<void> enableBluetooth() async {
    // Retrieving the current Bluetooth state
    _bluetoothState = await FlutterBluetoothSerial.instance.state;

    // If the bluetooth is off, then turn it on first
    // and then retrieve the devices that are paired.
    if (_bluetoothState == BluetoothState.STATE_OFF) {
      await FlutterBluetoothSerial.instance.requestEnable();
      await getPairedDevices();
      return true;
    } else {
      await getPairedDevices();
    }
    return false;
  }

  // For retrieving and storing the paired devices
  // in a list.
  Future<void> getPairedDevices() async {
    List<BluetoothDevice> devices = [];

    // To get the list of paired devices
    try {
      devices = await _bluetooth.getBondedDevices();
    } on PlatformException {
      print("Error");
    }

    // It is an error to call [setState] unless [mounted] is true.
    if (!mounted) {
      return;
    }

    // Store the [devices] list in the [_devicesList] for accessing
    // the list outside this class
    setState(() {
      _devicesList = devices;
    });
  }
  int page=0;
  // Now, its time to build the UI
  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    Widget pageone(){
      return Stack(
        children: [

          Positioned(top: 35*mq.size.height/759,left: 15*mq.size.width/392,
          child: IconButton(
            color: Color.fromRGBO(255, 246, 246, 1),
            icon: Icon(Icons.arrow_back),
            iconSize: 30*mq.size.width/392,
            onPressed: (){
              setState(() {
                page=0;
              });
            },
          ),),

         Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [



            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                GestureDetector(
                  onLongPressStart: _turnbuzzeron,
                  onLongPressUp: _turnbuzzeroff,
                  child: RawMaterialButton(
                    child: SizedBox(
                      width: 320*mq.size.width/392,
                      height: 90*mq.size.height/759,
                      child: Card(
                        shape: RoundedRectangleBorder(
                          side: new BorderSide(
                            color: _buzzstate == 0
                                ? Colors.grey
                                : _buzzstate == 1
                                ? Colors.green
                                : Colors.red,
                            width: 3*mq.size.width/392,
                          ),
                          borderRadius: BorderRadius.circular(10*mq.size.width/392),
                        ),
                        elevation: _buzzstate == 0 ? 4 : 0,

                        child: Center(
                          child: Text(
                            "BUZZ",
                            style: TextStyle(
                              fontSize: 27*mq.size.width/392,
                              color: _buzzstate == 0
                                  ? Colors.grey
                                  : _buzzstate == 1
                                  ? Colors.green
                                  : Colors.red,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

              ],
            ),

            SizedBox(
              height: 10*mq.size.height/759,
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                RawMaterialButton(
                  onPressed: _lightstate==0 ?_sendOnLightMessageToBluetooth :_lightstate==-1 ?_sendOnLightMessageToBluetooth: _sendOffLightMessageToBluetooth,
                  child: SizedBox(
                    width: 320*mq.size.width/392,
                    height: 90*mq.size.height/759,
                    child: Card(
                      shape: RoundedRectangleBorder(
                        side: new BorderSide(
                          color: _lightstate == 0
                              ? Colors.grey
                              : _lightstate == 1
                              ? Colors.green
                              : Colors.red,
                          width: 3*mq.size.width/392,
                        ),
                        borderRadius: BorderRadius.circular(10*mq.size.width/392),
                      ),
                      elevation: _lightstate == 0 ? 4 : 0,

                      child: Center(
                        child: Text(
                          "LIGHTS",
                          style: TextStyle(
                            fontSize: 27*mq.size.width/392,
                            color: _lightstate == 0
                                ? Colors.grey
                                : _lightstate == 1
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

              ],
            ),

            SizedBox(
              height: 10*mq.size.height/759,
            ),


            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                RawMaterialButton(
                  onPressed: _doorstate==0 || _doorstate==-1 ?_opendoor : _closedoor,
                  child: SizedBox(
                    width: 320*mq.size.width/392,
                    height: 90*mq.size.height/759,
                    child: Card(
                      shape: RoundedRectangleBorder(
                        side: new BorderSide(
                          color: _doorstate == 0
                              ? Colors.grey
                              : _doorstate == 1
                              ? Colors.green
                              : Colors.red,
                          width: 3*mq.size.width/392,
                        ),
                        borderRadius: BorderRadius.circular(10*mq.size.width/392),
                      ),
                      elevation: _doorstate == 0 ? 4 : 0,

                      child: Center(
                        child: Text(
                          "DOOR",
                          style: TextStyle(
                            fontSize: 27*mq.size.width/392,
                            color: _doorstate == 0
                                ? Colors.grey
                                : _doorstate == 1
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

          ],
        ),
      ],
      );



    };

    Widget pagezero(){
      return Container(
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: <Widget>[

            Visibility(
              visible: _isButtonUnavailable &&
                  _bluetoothState == BluetoothState.STATE_ON,
              child: LinearProgressIndicator(
                minHeight: 30*mq.size.height/759,
                backgroundColor: Color.fromRGBO(54, 53, 64, 1),
                valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
              ),
            ),
            SizedBox(
              height: 100*mq.size.height/759,
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                  100 * mq.size.width / 392, 40 * mq.size.height / 759,
                  100 * mq.size.width / 392, 25 * mq.size.height / 759),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Text(
                      'Enable Bluetooth',
                      style: TextStyle(
                        color:  Color.fromRGBO(255, 246, 246, 1),
                        fontSize: 17 * mq.size.width / 392,
                      ),
                    ),
                  ),
                  Switch(
                    activeColor:  Color.fromRGBO(255, 246, 246, 1),
                    value: _bluetoothState.isEnabled,
                    onChanged: (bool value) {
                      future() async {
                        if (value) {
                          await FlutterBluetoothSerial.instance
                              .requestEnable();
                        } else {
                          await FlutterBluetoothSerial.instance
                              .requestDisable();
                        }

                        await getPairedDevices();
                        _isButtonUnavailable = false;

                        if (_connected) {
                          _disconnect();
                        }
                      }

                      future().then((_) {
                        setState(() {});
                      });
                    },
                  )
                ],
              ),
            ),
            Stack(
              children: <Widget>[
                Column(
                  children: <Widget>[
                    Padding(
                      padding: EdgeInsets.only(top: 5 * mq.size.height / 759),
                      child: Text(
                        "Select a paired device to connect to",
                        style: TextStyle(fontSize: 18 * mq.size.width / 392,
                            color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: <Widget>[
                          Text(
                            'Device:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold, color: Color.fromRGBO(255, 246, 246, 1),
                            ),
                          ),
                          DropdownButton(
                            iconDisabledColor: Color.fromRGBO(255, 246, 246, 1),
                            iconEnabledColor: Color.fromRGBO(255, 246, 246, 1),
                            items:_getDeviceItems(),
                            onChanged: (value) =>
                                setState(() => _device = value),
                            value: _devicesList.isNotEmpty ? _device : null,
                          ),
                          RaisedButton(
                            onPressed: _isButtonUnavailable
                                ? null
                                : _connected ? _disconnect : _connect,
                            child:
                            Text(_connected ? 'Disconnect' : 'Connect'),
                          ),
                        ],
                      ),
                    ),

                    Padding(
                      padding: EdgeInsets.only(top: 50 * mq.size.height /
                          759),
                      child: SizedBox(
                        width: 250 * mq.size.width / 392,
                        height: 100 * mq.size.height / 769,
                        child: MaterialButton(
                          color: _connected ? Colors.blue : Colors.grey,
                          onPressed: () {
                            if (_connected)
                              setState(() {
                               page=1;
                              });
                            else
                              null;
                          },
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                                15 * mq.size.width / 375),),
                          elevation: _connected ? 3 : 0,
                          child: Text('START', style: TextStyle(
                              fontSize: 23 * mq.size.width / 392),),

                        ),
                      ),

                    )

                  ],
                ),

              ],
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(top: 40 * mq.size.height / 759,
                    left: 15 * mq.size.width / 392,
                    right: 15 * mq.size.width / 392),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        "NOTE: If you cannot find the device in the list, please pair the device by going to the bluetooth settings",
                        style: TextStyle(
                          fontSize: 15 * mq.size.width / 392,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      SizedBox(height: 15),
                      RaisedButton(
                        elevation: 2,
                        child: Text("Bluetooth Settings"),
                        onPressed: () {
                          FlutterBluetoothSerial.instance.openSettings();
                        },
                      ),
                    ],
                  ),
                ),
              ),
            )
          ],
        ),
      );
    };



    /////////////////////////////////////////////////////////////////////
    return MaterialApp(
      home: Scaffold(
        key: _scaffoldKey,
        backgroundColor: Color.fromRGBO(54, 53, 64, 1),
        body: page==0?pagezero():pageone(),
      ),
    );
  }

  // Create the List of devices to be shown in Dropdown Menu
  List<DropdownMenuItem<BluetoothDevice>> _getDeviceItems() {
    List<DropdownMenuItem<BluetoothDevice>> items = [];
    if (_devicesList.isEmpty) {
      items.add(DropdownMenuItem(
        child: Text('NONE'),
      ));
    } else {
      _devicesList.forEach((device) {
        items.add(DropdownMenuItem(
          child: Text(device.name),
          value: device,
        ));
      });
    }
    return items;
  }

  // Method to connect to bluetooth
  void _connect() async {
    setState(() {
      _isButtonUnavailable = true;
    });
    if (_device == null) {
      show('No device selected');
    } else {
      if (!isConnected) {
        await BluetoothConnection.toAddress(_device.address)
            .then((_connection) {
          print('Connected to the device');
          connection = _connection;
          setState(() {
            _connected = true;
          });

          connection.input.listen(null).onDone(() {
            if (isDisconnecting) {
              print('Disconnecting locally!');
            } else {
              print('Disconnected remotely!');
            }
            if (this.mounted) {
              setState(() {});
            }
          });
        }).catchError((error) {
          print('Cannot connect, exception occurred');
          print(error);
        });
        show('Device connected');

        setState(() => _isButtonUnavailable = false);
      }
    }
  }

  // Method to disconnect bluetooth
  void _disconnect() async {
    setState(() {
      _isButtonUnavailable = true;
      _deviceState = 0;
      _lightstate=0;
    });

    await connection.close();
    show('Device disconnected');
    if (!connection.isConnected) {
      setState(() {
        _connected = false;
        _isButtonUnavailable = false;
      });
    }
  }

  // Method to send message,
  // for turning the Bluetooth device on
  void _sendOnLightMessageToBluetooth() async {
    connection.output.add(utf8.encode("1" + "\r\n"));
    await connection.output.allSent;
    show('Light Turned On');
    setState(() {
      _lightstate = 1; // device on
    });
  }

  // Method to send message,
  // for turning the Bluetooth device off
  void _sendOffLightMessageToBluetooth() async {
    connection.output.add(utf8.encode("0" + "\r\n"));
    await connection.output.allSent;
    show('Light Turned Off');
    setState(() {
      _lightstate = -1; // device off
    });
  }


  void _turnbuzzeron(LongPressStartDetails  details) async {
    connection.output.add(utf8.encode("2" + "\r\n"));
    await connection.output.allSent;
    show('Buzzer Turned On');
    setState(() {
      _buzzstate = 1; // device on
    });

  }

  void _turnbuzzeroff() async {
    connection.output.add(utf8.encode("3" + "\r\n"));
    await connection.output.allSent;
    show('Buzzer Turned Off');
    setState(() {
      _buzzstate = -1; // device off
    });
  }

  void _opendoor() async {
    connection.output.add(utf8.encode("4" + "\r\n"));
    await connection.output.allSent;
    show('Door opened');
    setState(() {
      _doorstate = 1; // device on
    });

  }

  void _closedoor() async {
    connection.output.add(utf8.encode("5" + "\r\n"));
    await connection.output.allSent;
    show('Door closed');
    setState(() {
      _doorstate = -1; // device off
    });
  }

  // Method to show a Snackbar,
  // taking message as the text
  Future show(
    String message, {
    Duration duration: const Duration(seconds: 3),
  }) async {
    await new Future.delayed(new Duration(milliseconds: 100));
    _scaffoldKey.currentState.showSnackBar(
      new SnackBar(
        content: new Text(
          message,
        ),
        duration: duration,
      ),
    );
  }
}
