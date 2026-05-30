import 'package:flutter/material.dart';

class MapTable extends StatefulWidget {
  final String title;
  final List<double> rpmAxis;
  final List<double> loadAxis;
  final List<List<double>> values;
  final ValueChanged<({int row, int col, double value})>? onCellChanged;

  const MapTable({
    super.key,
    required this.title,
    required this.rpmAxis,
    required this.loadAxis,
    required this.values,
    this.onCellChanged,
  });

  @override
  State<MapTable> createState() => _MapTableState();
}

class _MapTableState extends State<MapTable> {
  int? _selectedRow;
  int? _selectedCol;

  Color _cellColor(double value) {
    // Gradiente azul (baixo) → verde (médio) → vermelho (alto) como TunerStudio
    if (value < 40)  return Color.lerp(const Color(0xFF0D47A1), const Color(0xFF1565C0), value / 40)!;
    if (value < 70)  return Color.lerp(const Color(0xFF2E7D32), Colors.green, (value - 40) / 30)!;
    if (value < 90)  return Color.lerp(Colors.green, Colors.orange, (value - 70) / 20)!;
    return Color.lerp(Colors.orange, Colors.red, (value - 90) / 20)!;
  }

  void _onCellTap(int row, int col) {
    setState(() {
      _selectedRow = row;
      _selectedCol = col;
    });
    if (widget.onCellChanged == null) return;

    showDialog<double>(
      context: context,
      builder: (_) => _ValueEditDialog(
        current: widget.values[row][col],
        onConfirm: (v) => widget.onCellChanged!(
          (row: row, col: col, value: v),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(widget.title,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cabeçalho RPM
              Row(children: [
                const SizedBox(width: 40),
                ...widget.rpmAxis.map((rpm) => _headerCell('${rpm ~/ 1000}k')),
              ]),
              // Linhas da tabela (carga × RPM)
              ...List.generate(widget.loadAxis.length, (row) {
                return Row(children: [
                  _headerCell('${widget.loadAxis[row].toInt()}'),
                  ...List.generate(widget.rpmAxis.length, (col) {
                    final val = widget.values[row][col];
                    final selected = _selectedRow == row && _selectedCol == col;
                    return GestureDetector(
                      onTap: () => _onCellTap(row, col),
                      child: Container(
                        width: 36,
                        height: 28,
                        margin: const EdgeInsets.all(1),
                        decoration: BoxDecoration(
                          color: _cellColor(val),
                          border: selected
                              ? Border.all(color: Colors.white, width: 2)
                              : null,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          val.toStringAsFixed(0),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  }),
                ]);
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _headerCell(String text) {
    return Container(
      width: 36,
      height: 22,
      alignment: Alignment.center,
      child: Text(text,
          style: const TextStyle(color: Colors.white54, fontSize: 9)),
    );
  }
}

class _ValueEditDialog extends StatefulWidget {
  final double current;
  final ValueChanged<double> onConfirm;

  const _ValueEditDialog({required this.current, required this.onConfirm});

  @override
  State<_ValueEditDialog> createState() => _ValueEditDialogState();
}

class _ValueEditDialogState extends State<_ValueEditDialog> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.current.toStringAsFixed(1));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1E1E1E),
      title: const Text('Editar Célula', style: TextStyle(color: Colors.white)),
      content: TextField(
        controller: _ctrl,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        autofocus: true,
        style: const TextStyle(color: Colors.white),
        decoration: const InputDecoration(
          labelText: 'Valor (%)',
          labelStyle: TextStyle(color: Colors.white54),
          enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white30)),
          focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.blue)),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            final v = double.tryParse(_ctrl.text);
            if (v != null) {
              widget.onConfirm(v.clamp(0, 120));
            }
            Navigator.pop(context);
          },
          child: const Text('OK'),
        ),
      ],
    );
  }
}
