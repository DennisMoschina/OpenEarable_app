import 'package:flutter/material.dart';
import 'package:open_earable_flutter/src/open_earable_flutter.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'ble.dart';
import 'dart:async';

final Map<int, String> jingleMap = {
  0: 'IDLE',
  1: 'NOTIFICATION',
  2: 'SUCCESS',
  3: 'ERROR',
  4: 'ALARM',
  5: 'PING',
  6: 'OPEN',
  7: 'CLOSE',
  8: 'CLICK',
};

final Map<int, String> waveFormMap = {
  1: 'sine',
  2: 'square',
  3: 'triangle',
  4: 'saw',
};

int getKeyFromValue(String value, Map<int, String> map) {
  for (var entry in map.entries) {
    if (entry.value == value) {
      return entry.key;
    }
  }
  return 1;
}

class ActuatorsTab extends StatefulWidget {
  final OpenEarable _openEarable;
  ActuatorsTab(this._openEarable);
  @override
  _ActuatorsTabState createState() => _ActuatorsTabState(_openEarable);
}

class _ActuatorsTabState extends State<ActuatorsTab> {
  final OpenEarable _openEarable;
  _ActuatorsTabState(this._openEarable);
  Color _selectedColor = Colors.deepPurple;

  TextEditingController _imuTextController = TextEditingController(text: "0");
  TextEditingController _barometerTextController =
      TextEditingController(text: "0");
  List<String> microphoneOptions = [
    "16000",
    "20000",
    "25000",
    "31250",
    "33333",
    "40000",
    "41667",
    "50000",
    "62500"
  ];
  late String selectedMicrophoneOption; // Initialize with the first option
  TextEditingController _filenameTextController =
      TextEditingController(text: "filename.wav");
  TextEditingController _jingleTextController =
      TextEditingController(text: jingleMap[1]);
  TextEditingController _audioFrequencyTextController =
      TextEditingController(text: "100");
  TextEditingController _audioPercentageTextController =
      TextEditingController(text: "50");
  TextEditingController _audioWaveFormTextController =
      TextEditingController(text: waveFormMap[1]);
  StreamSubscription<bool>? _connectionStateSubscription;
  StreamSubscription<dynamic>? _batteryLevelSubscription;
  bool connected = false;
  String earableDeviceName = "OpenEarable";
  int earableSOC = 0;
  bool earableCharging = false;
  String earableFirmware = "0.0.0";
  int _selectedRadio = 0;
  bool _imuSettingSelected = true;
  bool _barometerSettingSelected = true;
  bool _microphoneSettingSelected = true;

  Timer? rainbowTimer;
  late bool rainbowModeActive;

  @override
  void dispose() {
    super.dispose();
    _connectionStateSubscription?.cancel();
    _batteryLevelSubscription?.cancel();
  }

  @override
  void initState() {
    _connectionStateSubscription =
        _openEarable.bleManager.connectionStateStream.listen((connected) {
      setState(() {
        this.connected = connected;

        if (connected) {
          getNameAndSOC();
        }
      });
    });
    setState(() {
      selectedMicrophoneOption = microphoneOptions[0];
      connected = _openEarable.bleManager.connected;

      if (connected) {
        getNameAndSOC();
      }
      super.initState();
    });
  }

  void getNameAndSOC() {
    String? name = _openEarable.bleManager.connectedDevice?.name;
    earableDeviceName = name ?? "";

    earableFirmware = _openEarable.deviceFirmwareVersion ?? "0.0.0";

    _batteryLevelSubscription = _openEarable.sensorManager
        .getBatteryLevelStream()
        .listen((batteryLevel) {
      setState(() {
        earableSOC = batteryLevel[0].toInt();
      });
    });
  }

  void playButtonPressed() {
    switch (_selectedRadio) {
      case 0:
        playWAV();
        break;
      case 1:
        playJingle();
        break;
      case 2:
        playFrequencySound();
    }
  }

  void pauseButtonPressed() {
    switch (_selectedRadio) {
      case 0:
        pauseWAV();
        break;
      case 1:
        stopJingle();
        break;
      case 2:
        stopFrequencySound();
    }
  }

  void stopButtonPressed() {
    switch (_selectedRadio) {
      case 0:
        stopWAV();
        break;
      case 1:
        stopJingle();
        break;
      case 2:
        stopFrequencySound();
    }
  }

  void resetButtonPressed() {
    stopButtonPressed();
  }

  void playJingle() {
    _openEarable.audioPlayer.setJingleState(AudioPlayerState.start,
        name: _jingleTextController.text);
  }

  void playWAV() {
    _openEarable.audioPlayer.setWavState(AudioPlayerState.start,
        name: _filenameTextController.text);
  }

  void stopJingle() {
    _openEarable.audioPlayer.setJingleState(AudioPlayerState.stop);
  }

  void setLEDColor() {
    stopRainbowMode();
    _openEarable.rgbLed.writeLedColor(
        r: _selectedColor.red, g: _selectedColor.green, b: _selectedColor.blue);
  }

  void pauseWAV() {
    _openEarable.audioPlayer.setWavState(AudioPlayerState.pause);
  }

  void stopWAV() {
    _openEarable.audioPlayer.setWavState(AudioPlayerState.stop);
  }

  void playFrequencySound() {
    double frequency =
        double.tryParse(_audioFrequencyTextController.text) ?? 100.0;
    int waveForm =
        getKeyFromValue(_audioWaveFormTextController.text, waveFormMap);
    _openEarable.audioPlayer.setFrequencyState(AudioPlayerState.start,
        frequency: frequency, waveForm: waveForm);
  }

  void stopFrequencySound() {
    _openEarable.audioPlayer
        .setFrequencyState(AudioPlayerState.stop, frequency: 0.0, waveForm: 0);
  }

  void turnLEDoff() {
    stopRainbowMode();
    _openEarable.rgbLed.writeLedColor(r: 0, g: 0, b: 0);
  }

  void startRainbowMode() {
    if (rainbowModeActive) return;

    rainbowModeActive = true;

    double h = 0;
    const double increment = 0.01;

    rainbowTimer = Timer.periodic(Duration(milliseconds: 300), (Timer timer) {
      Map<String, int> rgbValue = hslToRgb(h, 1, 0.5);
      _openEarable.rgbLed.writeLedColor(
          r: rgbValue['r']!, g: rgbValue['g']!, b: rgbValue['b']!);

      h += increment;
      if (h > 1) h = 0;
    });
  }

  void stopRainbowMode() {
    rainbowModeActive = false;
    if (rainbowTimer == null) {
      return;
    }
    if (rainbowTimer!.isActive) {
      rainbowTimer?.cancel();
    }
  }

  Map<String, int> hexToRgb(String hex) {
    hex = hex.startsWith('#') ? hex.substring(1) : hex;

    int bigint = int.parse(hex, radix: 16);
    int r = (bigint >> 16) & 255;
    int g = (bigint >> 8) & 255;
    int b = bigint & 255;

    return {'r': r, 'g': g, 'b': b};
  }

  Map<String, int> hslToRgb(double h, double s, double l) {
    double r, g, b;

    if (s == 0) {
      r = g = b = l;
    } else {
      double hue2rgb(double p, double q, double t) {
        if (t < 0) t += 1;
        if (t > 1) t -= 1;
        if (t < 1 / 6) return p + (q - p) * 6 * t;
        if (t < 1 / 2) return q;
        if (t < 2 / 3) return p + (q - p) * (2 / 3 - t) * 6;
        return p;
      }

      double q = l < 0.5 ? l * (1 + s) : l + s - l * s;
      double p = 2 * l - q;
      r = hue2rgb(p, q, h + 1 / 3);
      g = hue2rgb(p, q, h);
      b = hue2rgb(p, q, h - 1 / 3);
    }

    return {
      'r': (r * 255).round(),
      'g': (g * 255).round(),
      'b': (b * 255).round()
    };
  }

  bool isValidHex(String hex) {
    return RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(hex);
  }

  void _openColorPicker() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Pick a color for the RGB LED'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: _selectedColor,
              onColorChanged: (color) {
                setState(() {
                  _selectedColor = color;
                });
              },
              showLabel: true,
              pickerAreaHeightPercent: 0.8,
              enableAlpha: false,
            ),
          ),
          actions: <Widget>[
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Done'),
            ),
          ],
        );
      },
    );
  }

  void _showJinglePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: jingleMap.values.map((String option) {
              return ListTile(
                onTap: connected
                    ? () {
                        setState(() {
                          _jingleTextController.text = option;
                          Navigator.pop(context);
                        });
                      }
                    : null,
                title: Text(option),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _showWaveFormPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: waveFormMap.values.map((String option) {
              return ListTile(
                onTap: connected
                    ? () {
                        setState(() {
                          _audioWaveFormTextController.text = option;
                          Navigator.pop(context);
                        });
                      }
                    : null,
                title: Text(option),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Color _getCheckboxColor(Set<MaterialState> states) {
    const Set<MaterialState> interactiveStates = <MaterialState>{
      MaterialState.pressed,
      MaterialState.hovered,
      MaterialState.focused,
      MaterialState.selected,
    };
    if (states.any(interactiveStates.contains)) {
      return Theme.of(context).colorScheme.secondary;
    }
    return Theme.of(context).colorScheme.primary;
  }

  void showErrorDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Invalid sampling rates'),
          content: Text(
              'Please ensure that sampling rates of IMU and Barometer are not greater than 30 Hz'),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
          ],
        );
      },
    );
  }

  Widget microphoneSettingRow(
      String sensorName, bool boolean, Function(bool?) onValueChanged) {
    return Row(
      children: [
        Checkbox(
          checkColor: Theme.of(context).colorScheme.primary,
          fillColor: MaterialStateProperty.resolveWith(_getCheckboxColor),
          value: boolean,
          onChanged: onValueChanged,
        ),
        Text(sensorName),
        Spacer(),
        Container(
            decoration: BoxDecoration(
              color: connected ? Colors.white : Colors.grey[200],
              borderRadius: BorderRadius.circular(4.0),
            ),
            child: SizedBox(
                height: 37,
                width: 100,
                child: Container(
                    alignment: Alignment.centerRight,
                    child: DropdownButton<String>(
                      dropdownColor:
                          connected ? Colors.white : Colors.grey[200],
                      alignment: Alignment.centerRight,
                      value: selectedMicrophoneOption,
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedMicrophoneOption = newValue!;
                        });
                      },
                      items: microphoneOptions.map((String value) {
                        return DropdownMenuItem<String>(
                          alignment: Alignment.centerRight,
                          value: value,
                          child: Text(
                            value,
                            style: TextStyle(
                              color: connected ? Colors.black : Colors.grey,
                            ),
                            textAlign: TextAlign.end,
                          ),
                        );
                      }).toList(),
                      underline: Container(),
                      icon: Icon(
                        Icons.arrow_drop_down,
                        color: connected ? Colors.black : Colors.grey,
                      ),
                    )))),
        SizedBox(width: 8),
        Text("Hz"),
      ],
    );
  }

  Widget sensorSettingRow(
    String sensorName,
    TextEditingController controller,
    bool boolean,
    Function(bool?) onValueChanged,
  ) {
    return Row(
      children: [
        Checkbox(
          checkColor: Theme.of(context).colorScheme.primary,
          fillColor: MaterialStateProperty.resolveWith(_getCheckboxColor),
          value: boolean,
          onChanged: onValueChanged,
        ),
        Text(sensorName),
        Spacer(),
        SizedBox(
          height: 37,
          width: 100,
          child: TextField(
            keyboardType: TextInputType.number,
            controller: controller,
            obscureText: false,
            enabled: connected,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: connected ? Colors.black : Colors.grey,
            ),
            decoration: InputDecoration(
              contentPadding: EdgeInsets.all(10),
              border: OutlineInputBorder(),
              floatingLabelBehavior: FloatingLabelBehavior.never,
              labelText: '0',
              labelStyle: TextStyle(
                color: connected ? Colors.black : Colors.grey,
              ),
              filled: true,
              fillColor: connected ? Colors.white : Colors.grey[200],
            ),
          ),
        ),
        SizedBox(width: 8),
        Text("Hz"),
      ],
    );
  }

  void writeSensorConfigs() {
    String imuText =
        (_imuTextController.text == "") ? "0" : _imuTextController.text;
    String barometerText = (_barometerTextController.text == "")
        ? "0"
        : _barometerTextController.text;
    double? imuSamplingRate = double.tryParse(imuText);
    double? barometerSamplingRate = double.tryParse(barometerText);
    double? microphoneSamplingRate = double.tryParse(selectedMicrophoneOption);
    if (imuSamplingRate == null ||
        barometerSamplingRate == null ||
        microphoneSamplingRate == null ||
        imuSamplingRate > 30 ||
        imuSamplingRate < 0 ||
        barometerSamplingRate > 30 ||
        barometerSamplingRate < 0) {
      showErrorDialog(context);
    }
    OpenEarableSensorConfig imuConfig = OpenEarableSensorConfig(
        sensorId: 0,
        samplingRate: _imuSettingSelected ? imuSamplingRate! : 0,
        latency: 0);
    OpenEarableSensorConfig barometerConfig = OpenEarableSensorConfig(
        sensorId: 1,
        samplingRate: _barometerSettingSelected ? barometerSamplingRate! : 0,
        latency: 0);
    OpenEarableSensorConfig microphoneConfig = OpenEarableSensorConfig(
        sensorId: 2,
        samplingRate: _microphoneSettingSelected ? microphoneSamplingRate! : 0,
        latency: 0);
    _openEarable.sensorManager.writeSensorConfig(imuConfig);
    _openEarable.sensorManager.writeSensorConfig(barometerConfig);
    print(barometerConfig);
    _openEarable.sensorManager.writeSensorConfig(microphoneConfig);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
        child: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: 5,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5.0),
                  child: Card(
                    color: Color(0xff161618),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Device',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 5),
                          Row(
                            children: [
                              if (connected)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "$earableDeviceName ($earableSOC%)",
                                      style: TextStyle(
                                        color:
                                            Color.fromRGBO(168, 168, 172, 1.0),
                                        fontSize: 15.0,
                                      ),
                                    ),
                                    Text(
                                      "Firmware $earableFirmware",
                                      style: TextStyle(
                                        color:
                                            Color.fromRGBO(168, 168, 172, 1.0),
                                        fontSize: 15.0,
                                      ),
                                    ),
                                  ],
                                ),
                              if (!connected)
                                Text(
                                  "OpenEarable not connected.",
                                  style: TextStyle(
                                    color: Color.fromRGBO(168, 168, 172, 1.0),
                                    fontSize: 15.0,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                            ],
                          ),
                          Visibility(
                            visible: !connected,
                            child: Column(
                              children: [
                                SizedBox(height: 10),
                                Row(
                                  children: [
                                    Expanded(
                                      child: SizedBox(
                                        height: 37.0,
                                        child: ElevatedButton(
                                          onPressed: () {
                                            Navigator.of(context).push(
                                                MaterialPageRoute(
                                                    builder: (context) =>
                                                        BLEPage(_openEarable)));
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: !connected
                                                ? Color(0xff77F2A1)
                                                : Color(0xfff27777),
                                            foregroundColor: Colors.black,
                                          ),
                                          child: Text("Connect"),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5.0),
                  child: Card(
                    //Audio Player Card
                    color: Color(0xff161618),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sensor Control',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          sensorSettingRow(
                              "IMU", _imuTextController, _imuSettingSelected,
                              (bool? newValue) {
                            if (newValue != null) {
                              setState(() {
                                _imuSettingSelected = newValue;
                              });
                            }
                          }),
                          sensorSettingRow(
                              "Barometer",
                              _barometerTextController,
                              _barometerSettingSelected, (bool? newValue) {
                            if (newValue != null) {
                              setState(() {
                                _barometerSettingSelected = newValue;
                              });
                            }
                          }),
                          microphoneSettingRow(
                              "Microphone", _microphoneSettingSelected,
                              (bool? newValue) {
                            if (newValue != null) {
                              setState(() {
                                _microphoneSettingSelected = newValue;
                              });
                            }
                          }),
                          SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: SizedBox(
                                  height: 37.0,
                                  child: ElevatedButton(
                                    onPressed: writeSensorConfigs,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: connected
                                          ? Theme.of(context)
                                              .colorScheme
                                              .secondary
                                          : Colors.grey,
                                      foregroundColor: Colors.black,
                                      enableFeedback: connected,
                                    ),
                                    child: Text("Set Configuration"),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5.0),
                  child: Card(
                    //Audio Player Card
                    color: Color(0xff161618),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Audio Player',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Row(
                            children: [
                              Radio(
                                value: 0,
                                groupValue: _selectedRadio,
                                onChanged: (int? value) {
                                  setState(() {
                                    _selectedRadio = value ?? 0;
                                  });
                                },
                              ),
                              Expanded(
                                child: SizedBox(
                                  height: 37.0,
                                  child: TextField(
                                    controller: _filenameTextController,
                                    obscureText: false,
                                    enabled: connected,
                                    style: TextStyle(
                                        color: connected
                                            ? Colors.black
                                            : Colors.grey),
                                    decoration: InputDecoration(
                                      contentPadding: EdgeInsets.all(10),
                                      border: OutlineInputBorder(),
                                      floatingLabelBehavior:
                                          FloatingLabelBehavior.never,
                                      labelText: 'filename.wav',
                                      labelStyle: TextStyle(
                                          color: connected
                                              ? Colors.black
                                              : Colors.grey),
                                      filled: true,
                                      fillColor: connected
                                          ? Colors.white
                                          : Colors.grey[200],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Radio(
                                value: 1,
                                groupValue: _selectedRadio,
                                onChanged: (int? value) {
                                  setState(() {
                                    _selectedRadio = value ?? 0;
                                  });
                                },
                              ),
                              Expanded(
                                child: SizedBox(
                                  height: 37.0,
                                  child: InkWell(
                                    onTap: connected
                                        ? () {
                                            _showJinglePicker(context);
                                          }
                                        : null,
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 12.0),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Colors.grey),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            _jingleTextController.text,
                                            style: TextStyle(fontSize: 16.0),
                                          ),
                                          Icon(Icons.arrow_drop_down),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Radio(
                                value: 2,
                                groupValue: _selectedRadio,
                                onChanged: (int? value) {
                                  setState(() {
                                    _selectedRadio = value ?? 0;
                                  });
                                },
                              ),
                              SizedBox(
                                height: 37.0,
                                width: 80,
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 0),
                                  child: TextField(
                                    controller: _audioFrequencyTextController,
                                    textAlign: TextAlign.end,
                                    style: TextStyle(
                                        color: connected
                                            ? Colors.black
                                            : Colors.grey),
                                    decoration: InputDecoration(
                                      contentPadding: EdgeInsets.all(10),
                                      floatingLabelBehavior:
                                          FloatingLabelBehavior.never,
                                      border: OutlineInputBorder(),
                                      labelText: '100',
                                      filled: true,
                                      labelStyle: TextStyle(
                                          color: connected
                                              ? Colors.black
                                              : Colors.grey),
                                      fillColor: connected
                                          ? Colors.white
                                          : Colors.grey[200],
                                    ),
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 5),
                                child: Text(
                                  'Hz',
                                  style: TextStyle(
                                      color: connected
                                          ? Colors.white
                                          : Colors
                                              .grey), // Set text color to white
                                ),
                              ),
                              Spacer(),
                              SizedBox(
                                height: 37.0,
                                width: 52,
                                child: TextField(
                                  controller: _audioPercentageTextController,
                                  textAlign: TextAlign.end,
                                  autofocus: false,
                                  style: TextStyle(
                                      color: connected
                                          ? Colors.black
                                          : Colors.grey),
                                  decoration: InputDecoration(
                                    contentPadding: EdgeInsets.all(10),
                                    floatingLabelBehavior:
                                        FloatingLabelBehavior.never,
                                    border: OutlineInputBorder(),
                                    labelText: '50',
                                    filled: true,
                                    isDense: true,
                                    counterText: "",
                                    labelStyle: TextStyle(
                                        color: connected
                                            ? Colors.black
                                            : Colors.grey),
                                    fillColor: connected
                                        ? Colors.white
                                        : Colors.grey[200],
                                  ),
                                  maxLength: 3,
                                  maxLines: 1,
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 5),
                                child: Text(
                                  '%',
                                  style: TextStyle(
                                      color: connected
                                          ? Colors.white
                                          : Colors
                                              .grey), // Set text color to white
                                ),
                              ),
                              Spacer(),
                              SizedBox(
                                height: 37.0,
                                width: 107,
                                child: InkWell(
                                  onTap: connected
                                      ? () {
                                          _showWaveFormPicker(context);
                                        }
                                      : null,
                                  child: Container(
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 12.0),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          _audioWaveFormTextController.text,
                                          style: TextStyle(fontSize: 16.0),
                                        ),
                                        Icon(Icons.arrow_drop_down),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment
                                .spaceBetween, // Align buttons to the space between
                            children: [
                              ElevatedButton(
                                onPressed: connected ? playButtonPressed : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xff77F2A1),
                                  foregroundColor: Colors.black,
                                ),
                                child: Icon(Icons.play_arrow_outlined),
                              ),
                              ElevatedButton(
                                onPressed:
                                    connected ? pauseButtonPressed : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xffe0f277),
                                  foregroundColor: Colors.black,
                                ),
                                child: Icon(Icons.pause),
                              ),
                              ElevatedButton(
                                onPressed: connected ? stopButtonPressed : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xfff27777),
                                  foregroundColor: Colors.black,
                                ),
                                child: Icon(Icons.stop_outlined),
                              ),
                              SizedBox(
                                width: 100,
                                child: ElevatedButton(
                                  onPressed:
                                      connected ? resetButtonPressed : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Color(0xff53515b),
                                    foregroundColor: Colors.white,
                                  ),
                                  child: Text('Reset'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5.0),
                    child: Card(
                      //LED Color Picker Card
                      color: Color(0xff161618),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'LED Color',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: connected
                                      ? _openColorPicker
                                      : null, // Open color picker
                                  child: Container(
                                    width: 66,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: _selectedColor,
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 5),
                                SizedBox(
                                  width: 66,
                                  child: ElevatedButton(
                                    onPressed: connected ? setLEDColor : null,
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: Color(
                                            0xff53515b), // Set the background color to grey
                                        foregroundColor: Colors.white),
                                    child: Text('Set'),
                                  ),
                                ),
                                SizedBox(width: 5),
                                ElevatedButton(
                                  onPressed:
                                      connected ? startRainbowMode : null,
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: Color(
                                          0xff53515b), // Set the background color to grey
                                      foregroundColor: Colors.white),
                                  child: Text("🦄"),
                                ),
                                Spacer(),
                                ElevatedButton(
                                  onPressed: connected ? turnLEDoff : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Color(0xfff27777),
                                    foregroundColor: Colors.black,
                                  ),
                                  child: Text('Off'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    )),
              ],
            )));
  }
}
