class Shift {
  final String id;
  final DateTime startTime;
  final DateTime? endTime;
  final double startingCash;
  final double? endingCashActual;
  final double? difference;
  final String status;

  Shift({
    required this.id,
    required this.startTime,
    this.endTime,
    required this.startingCash,
    this.endingCashActual,
    this.difference,
    required this.status,
  });

  factory Shift.fromJson(Map<String, dynamic> json) {
    return Shift(
      id: json['id']?.toString() ?? '',
      startTime: DateTime.parse(json['start_time']),
      endTime: json['end_time'] != null
          ? DateTime.parse(json['end_time'])
          : null,
      startingCash:
          double.tryParse(json['starting_cash']?.toString() ?? '0') ?? 0,
      endingCashActual: json['ending_cash_actual'] != null
          ? double.tryParse(json['ending_cash_actual'].toString())
          : null,
      difference: json['difference'] != null
          ? double.tryParse(json['difference'].toString())
          : null,
      status: json['status'] ?? 'unknown',
    );
  }
}

class PaginatedShifts {
  final List<Shift> data;
  final int currentPage;
  final int lastPage;
  final int total;

  PaginatedShifts({
    required this.data,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  factory PaginatedShifts.fromJson(Map<String, dynamic> json) {
    final dataList = json['data'] as List? ?? [];
    return PaginatedShifts(
      data: dataList.map((e) => Shift.fromJson(e)).toList(),
      currentPage: json['current_page'] ?? 1,
      lastPage: json['last_page'] ?? 1,
      total: json['total'] ?? 0,
    );
  }
}
