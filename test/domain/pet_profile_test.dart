import 'package:flutter_test/flutter_test.dart';
import 'package:petji/domain/models.dart';

void main() {
  test('formats pet age in years and months for Chinese users', () {
    final pet = PetProfile(
      id: 'pet-1',
      name: 'Momo',
      species: PetSpecies.cat,
      breed: 'British Shorthair',
      birthday: DateTime(2024, 1, 15),
      sex: PetSex.female,
      isNeutered: true,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

    expect(pet.ageLabel(DateTime(2026, 6, 1)), '2岁4个月');
  });
}
