// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'game.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class GameAdapter extends TypeAdapter<Game> {
  @override
  final int typeId = 0;

  @override
  Game read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Game(
      title: fields[0] as String,
      platform: fields[1] as String,
      genre: fields[2] as String,
      status: fields[3] as GameStatus,
      dateAdded: fields[4] as DateTime,
      coverUrl: fields[5] as String?,
      summary: fields[6] as String?,
      rating: fields[7] as double?,
      notes: fields[8] as String?,
      isPhysical: fields[9] as bool?,
      progress: fields[10] as double?,
    );
  }

  @override
  void write(BinaryWriter writer, Game obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.title)
      ..writeByte(1)
      ..write(obj.platform)
      ..writeByte(2)
      ..write(obj.genre)
      ..writeByte(3)
      ..write(obj.status)
      ..writeByte(4)
      ..write(obj.dateAdded)
      ..writeByte(5)
      ..write(obj.coverUrl)
      ..writeByte(6)
      ..write(obj.summary)
      ..writeByte(7)
      ..write(obj.rating)
      ..writeByte(8)
      ..write(obj.notes)
      ..writeByte(9)
      ..write(obj.isPhysical)
      ..writeByte(10)
      ..write(obj.progress);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GameAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class GameStatusAdapter extends TypeAdapter<GameStatus> {
  @override
  final int typeId = 1;

  @override
  GameStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return GameStatus.backlog;
      case 1:
        return GameStatus.notStarted;
      case 2:
        return GameStatus.nowPlaying;
      case 3:
        return GameStatus.paused;
      case 4:
        return GameStatus.beaten;
      case 5:
        return GameStatus.dropped;
      default:
        return GameStatus.backlog;
    }
  }

  @override
  void write(BinaryWriter writer, GameStatus obj) {
    switch (obj) {
      case GameStatus.backlog:
        writer.writeByte(0);
        break;
      case GameStatus.notStarted:
        writer.writeByte(1);
        break;
      case GameStatus.nowPlaying:
        writer.writeByte(2);
        break;
      case GameStatus.paused:
        writer.writeByte(3);
        break;
      case GameStatus.beaten:
        writer.writeByte(4);
        break;
      case GameStatus.dropped:
        writer.writeByte(5);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GameStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
