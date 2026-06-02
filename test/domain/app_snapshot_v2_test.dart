import 'package:flutter_test/flutter_test.dart';
import 'package:petji/domain/models.dart';

void main() {
  test('empty snapshot is v2 with no seeded pet and no active pet', () {
    final snapshot = AppSnapshot.empty(now: DateTime(2026, 6, 1));

    expect(snapshot.version, 2);
    expect(snapshot.activePetId, isNull);
    expect(snapshot.pets, isEmpty);
    expect(snapshot.currentPet, isNull);
    expect(snapshot.todos, isEmpty);
    expect(snapshot.timelineEvents, isEmpty);
  });

  test('snapshot selects nullable current pet from activePetId', () {
    final now = DateTime(2026, 6, 1);
    final pet = PetProfile(
      id: 'pet-1',
      name: 'Momo',
      species: PetSpecies.cat,
      breed: 'British Shorthair',
      birthday: DateTime(2024, 1, 15),
      sex: PetSex.female,
      isNeutered: true,
      createdAt: now,
      updatedAt: now,
    );
    final snapshot = AppSnapshot.empty(
      now: now,
    ).copyWith(activePetId: pet.id, pets: [pet]);

    expect(snapshot.currentPet, pet);
    expect(snapshot.copyWith(activePetId: 'missing').currentPet, isNull);
  });

  test('round trips v2 todo and timeline models through snapshot json', () {
    final now = DateTime(2026, 6, 1, 9);
    final snapshot = AppSnapshot.empty(now: now).copyWith(
      activePetId: 'pet-1',
      todos: [
        TodoItem(
          id: 'todo-1',
          petId: 'pet-1',
          title: 'Book vaccine',
          status: TodoStatus.open,
          dueAt: DateTime(2026, 6, 5),
          createdAt: now,
          updatedAt: now,
        ),
      ],
      timelineEvents: [
        TimelineEvent(
          id: 'timeline-1',
          petId: 'pet-1',
          type: TimelineEventType.care,
          happenedAt: DateTime(2026, 6, 2, 10),
          title: 'Vaccine',
          sourceId: 'care-1',
          filePath: 'files/report.pdf',
          mediaPath: 'media/photo.jpg',
          createdAt: now,
          updatedAt: now,
        ),
      ],
    );

    final restored = AppSnapshot.fromJson(snapshot.toJson());

    expect(restored.version, 2);
    expect(restored.activePetId, 'pet-1');
    expect(restored.todos.single.status, TodoStatus.open);
    expect(restored.timelineEvents.single.type, TimelineEventType.care);
    expect(restored.timelineEvents.single.filePath, 'files/report.pdf');
    expect(restored.timelineEvents.single.mediaPath, 'media/photo.jpg');
  });
}
