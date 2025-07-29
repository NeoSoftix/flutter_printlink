enum PrinterConnectionType {
  bluetooth2,
  bluetooth4,
  usb,
  network,
  com,
  wifiP2P,
}

enum PrinterMode { pos, label }

enum PrinterAlignment { left, center, right }

enum PrinterTextSize { size1, size2, size3, size4 }

enum PrinterErrorStatus {
  none,
  cutter,
  flash,
  noPaper,
  voltage,
  overHeat,
  coverOpen,
  feedButton,
  paper,
  blackMark,
  paperJam,
  headUp,
  noRibbon,
  ribbonEnd,
  command,
  mechanical,
  unknownPaper,
  autoMeasure,
  head,
  motorOverHeat,
  battery,
  wrongLabel,
  ribbonError,
}

enum BarcodeType {
  upca,
  upce,
  jan13,
  jan8,
  code39,
  itf,
  codabar,
  code93,
  code128,
}

enum QRCodeSize { size3, size4, size5, size6, size7, size8 }
