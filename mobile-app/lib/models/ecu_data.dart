import 'dart:typed_data';

class EcuData {
  final int rpm;
  final int tps;
  final int mapKpa;
  final int cltC;
  final int iatC;
  final double afr;
  final double afrTarget;
  final int advDeg;
  final double battV;
  final int ve;
  final double pwMs;
  final int idleDuty;
  final bool synced;
  final int corrections;
  final int flexPct;
  final int baroKpa;
  final int loopMs;
  final int speedKmh;
  final double oilPressBar;
  final int knockRetDeg;

  // Alarmes
  final bool alarmClt;
  final bool alarmRpm;
  final bool alarmBatt;
  final bool alarmLean;
  final bool alarmRich;
  final bool alarmOil;
  final bool alarmKnock;

  bool get hasAlarm => alarmClt || alarmRpm || alarmBatt || alarmLean || alarmRich || alarmOil || alarmKnock;

  const EcuData({
    this.rpm = 0,
    this.tps = 0,
    this.mapKpa = 0,
    this.cltC = 0,
    this.iatC = 0,
    this.afr = 14.7,
    this.afrTarget = 14.7,
    this.advDeg = 0,
    this.battV = 12.0,
    this.ve = 0,
    this.pwMs = 0,
    this.idleDuty = 0,
    this.synced = false,
    this.corrections = 100,
    this.flexPct = 0,
    this.baroKpa = 101,
    this.loopMs = 0,
    this.speedKmh = 0,
    this.oilPressBar = 0.0,
    this.knockRetDeg = 0,
    this.alarmClt = false,
    this.alarmRpm = false,
    this.alarmBatt = false,
    this.alarmLean = false,
    this.alarmRich = false,
    this.alarmOil = false,
    this.alarmKnock = false,
  });

  // Parse do pacote BLE de 24 bytes enviado pelo ESP32
  factory EcuData.fromBytes(Uint8List bytes) {
    if (bytes.length < 20) return const EcuData();

    final bd = ByteData.sublistView(bytes);
    final alarms = bytes[14];

    return EcuData(
      rpm:         bd.getUint16(0, Endian.little),
      tps:         bytes[2],
      mapKpa:      bytes[3],
      cltC:        bytes[4].toSigned(8),
      iatC:        bytes[5].toSigned(8),
      afr:         bytes[6] / 10.0,
      afrTarget:   bytes[7] / 10.0,
      advDeg:      bytes[8].toSigned(8),
      battV:       bytes[9] / 10.0,
      ve:          bytes[10],
      pwMs:        bytes[11] / 10.0,
      idleDuty:    bytes[12],
      synced:      bytes[13] == 0,
      corrections: bytes[15],
      flexPct:     bytes[16],
      baroKpa:     bytes[17],
      loopMs:      bytes[18],
      speedKmh:    bytes.length > 19 ? bytes[19] : 0,
      oilPressBar: bytes.length > 20 ? bytes[20] / 10.0 : 0.0,
      knockRetDeg: bytes.length > 21 ? bytes[21] : 0,
      alarmClt:    (alarms & (1 << 0)) != 0,
      alarmRpm:    (alarms & (1 << 1)) != 0,
      alarmBatt:   (alarms & (1 << 2)) != 0,
      alarmLean:   (alarms & (1 << 3)) != 0,
      alarmRich:   (alarms & (1 << 4)) != 0,
      alarmOil:    (alarms & (1 << 5)) != 0,
      alarmKnock:  (alarms & (1 << 6)) != 0,
    );
  }

  // Cor do AFR: verde (stoich), amarelo (rico), vermelho (pobre)
  double get afrDeviation => (afr - afrTarget).abs();

  String get alarmDescription {
    final List<String> msgs = [];
    if (alarmClt)   msgs.add('TEMP MOTOR ALTA');
    if (alarmRpm)   msgs.add('RPM LIMIT');
    if (alarmBatt)  msgs.add('BATERIA BAIXA');
    if (alarmLean)  msgs.add('MISTURA POBRE');
    if (alarmRich)  msgs.add('MISTURA RICA');
    if (alarmOil)   msgs.add('PRESSÃO ÓLEO BAIXA');
    if (alarmKnock) msgs.add('DETONAÇÃO DETECTADA');
    return msgs.join(' | ');
  }
}

extension IntSigned on int {
  int toSigned(int bits) {
    final mask = 1 << (bits - 1);
    return (this & (mask - 1)) - (this & mask);
  }
}
