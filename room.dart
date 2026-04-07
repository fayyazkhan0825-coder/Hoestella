class Room {
  final String id;
  final String roomNumber;
  final int capacity;
  final int occupied;

  Room({
    required this.id,
    required this.roomNumber,
    required this.capacity,
    required this.occupied,
  });

  factory Room.fromMap(String id, Map<String, dynamic> data) {
    return Room(
      id: id,
      roomNumber: data['roomNumber'] as String? ?? '',
      capacity: (data['capacity'] as num?)?.toInt() ?? 0,
      occupied: (data['occupied'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'roomNumber': roomNumber,
      'capacity': capacity,
      'occupied': occupied,
    };
  }
}

