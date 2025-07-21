import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_screen.dart';

class RobotCarControlScreen extends StatefulWidget {
  @override
  _RobotCarControlScreenState createState() => _RobotCarControlScreenState();
}

class _RobotCarControlScreenState extends State<RobotCarControlScreen> {
  String _currentCommand = 'S'; // 'S' for stop
  double _currentDistance = 0.0;
  bool _isPowerOn = false;

  // Bluetooth variables
  FlutterBluetoothSerial _bluetooth = FlutterBluetoothSerial.instance;
  BluetoothConnection? _connection;
  bool _isConnecting = false;
  bool _isConnected = false;
  String _connectionStatus = "Disconnected";
  List<BluetoothDevice> _devicesList = [];
  BluetoothDevice? _selectedDevice;

  @override
  void initState() {
    super.initState();
    _requestPermissions();
    _bluetooth.onStateChanged().listen((state) {
      if (state == BluetoothState.STATE_ON) {
        _getBondedDevices();
      }
    });
  }

  Future<void> _requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();

    if (statuses.values.every((status) => status.isGranted)) {
      _getBondedDevices();
    }
  }

  Future<void> _getBondedDevices() async {
    List<BluetoothDevice> devices = await _bluetooth.getBondedDevices();
    setState(() {
      _devicesList = devices;
    });
  }

  Future<bool> _hasAllPermissions() async {
    final statuses = await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();
    return statuses.values.every((status) => status.isGranted);
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    // Check permissions
    if (!await _hasAllPermissions()) {
      _showSnackBar("Bluetooth and location permissions are required.");
      return;
    }
    // Check Bluetooth state
    if (await _bluetooth.state != BluetoothState.STATE_ON) {
      _showSnackBar("Please enable Bluetooth before connecting.");
      return;
    }
    setState(() {
      _isConnecting = true;
      _connectionStatus = "Connecting to {device.name}...";
    });
    // Add a short delay before connecting
    await Future.delayed(Duration(seconds: 1));
    try {
      BluetoothConnection connection =
          await BluetoothConnection.toAddress(device.address);
      setState(() {
        _connection = connection;
        _isConnected = true;
        _isConnecting = false;
        _connectionStatus = "Connected to {device.name}";
        _selectedDevice = device;
      });
      connection.input!.listen((Uint8List data) {
        String incomingData = String.fromCharCodes(data);
        if (incomingData.startsWith("distance:")) {
          setState(() {
            _currentDistance =
                double.tryParse(incomingData.split(":")[1]) ?? 0.0;
          });
        }
      }).onDone(() {
        _disconnect();
      });
    } catch (e) {
      _disconnect();
      print("Connection failed: {e.toString()}");
      _showSnackBar("Connection failed: {e.toString()}");
    }
  }

  void _disconnect() {
    if (_connection != null) {
      _connection!.close();
      _connection = null;
    }
    setState(() {
      _isConnected = false;
      _connectionStatus = "Disconnected";
      _selectedDevice = null;
    });
  }

  void _sendCommand(String command) {
    if (_isConnected && _connection != null) {
      // Always send the actual command plus newline so Arduino can read it
      final String commandWithNewline = '${command}\n';
      _connection!.output.add(Uint8List.fromList(commandWithNewline.codeUnits));
      _connection!.output.allSent.then((_) {
        print('Command sent: ${commandWithNewline}');
      });
    } else {
      _showSnackBar("Not connected to any device");
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), duration: Duration(seconds: 2)));
  }

  void _showBluetoothDrawer() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Bluetooth Devices",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(
                _connectionStatus,
                style: TextStyle(
                  color: _isConnected ? Colors.green : Colors.red,
                  fontSize: 16,
                ),
              ),
              Divider(),
              Expanded(
                child: ListView.builder(
                  itemCount: _devicesList.length,
                  itemBuilder: (context, index) {
                    BluetoothDevice device = _devicesList[index];
                    return ListTile(
                      leading: Icon(Icons.bluetooth),
                      title: Text(device.name ?? "Unknown Device"),
                      subtitle: Text(device.address),
                      trailing: _selectedDevice?.address == device.address
                          ? ElevatedButton(
                              onPressed: _disconnect,
                              child: Text("Disconnect"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                              ),
                            )
                          : ElevatedButton(
                              onPressed: () => _connectToDevice(device),
                              child: Text("Connect"),
                            ),
                    );
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    onPressed: _getBondedDevices,
                    child: Text("Refresh Devices"),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text("Close"),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Robot Car Controller'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.bluetooth),
            onPressed: _showBluetoothDrawer,
            tooltip: 'Bluetooth Settings',
          ),
          IconButton(
            icon: Icon(Icons.logout),
            tooltip: 'Sign Out',
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => AuthenticationScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade800, Colors.blue.shade400],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Distance indicator

            // Control pad
            _buildControlPad(),
          ],
        ),
      ),
    );
  }

  Widget _buildControlPad() {
    return Column(
      children: [
        // Forward button
        _buildControlButton(
          icon: Icons.arrow_upward,
          label: 'Forward',
          command: 'F',
          isActive: _currentCommand == 'F',
        ),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Left button
            _buildControlButton(
              icon: Icons.arrow_back,
              label: 'Left',
              command: 'L',
              isActive: _currentCommand == 'L',
            ),

            SizedBox(width: 80),

            // Right button
            _buildControlButton(
              icon: Icons.arrow_forward,
              label: 'Right',
              command: 'R',
              isActive: _currentCommand == 'R',
            ),
          ],
        ),

        // Backward button
        _buildControlButton(
          icon: Icons.arrow_downward,
          label: 'Backward',
          command: 'B',
          isActive: _currentCommand == 'B',
        ),

        // Stop switch
        Padding(
          padding: const EdgeInsets.only(top: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Switch',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(width: 20),
              Transform.scale(
                scale: 1.5,
                child: Switch(
                  value: _isPowerOn,
                  onChanged: (bool value) {
                    setState(() {
                      _isPowerOn = value;
                    });
                    if (value) {
                      _sendCommand('X');
                    } else {
                      _sendCommand('Y');
                    }
                  },
                  activeColor: Colors.greenAccent,
                  inactiveThumbColor: Colors.redAccent,
                  inactiveTrackColor: Colors.red.shade200,
                  activeTrackColor: Colors.green.shade200,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required String command,
    required bool isActive,
  }) {
    return GestureDetector(
      onTapDown: (_) {
        _currentCommand = command;
        _sendCommand(command);
      },
      onTapUp: (_) {
        _currentCommand = 'S';
        _sendCommand('S');
      },
      onTapCancel: () {
        _currentCommand = 'S';
        _sendCommand('S');
      },
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: isActive
                    ? Colors.white.withOpacity(0.3)
                    : Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(40),
                border: Border.all(
                  color: Colors.white,
                  width: isActive ? 3 : 1,
                ),
              ),
              child: Icon(
                icon,
                size: 50,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _connection?.close();
    super.dispose();
  }
}
