import 'models.dart';

const customBreedOption = '自定义';

const catBreedOptions = [
  '中华田园猫',
  '英国短毛猫',
  '美国短毛猫',
  '布偶猫',
  '缅因猫',
  '波斯猫',
  '暹罗猫',
  '孟加拉猫',
  '俄罗斯蓝猫',
  '斯芬克斯猫',
  '异国短毛猫',
  '阿比西尼亚猫',
  customBreedOption,
];

const dogBreedOptions = [
  '中华田园犬',
  '拉布拉多寻回犬',
  '金毛寻回犬',
  '法国斗牛犬',
  '德国牧羊犬',
  '贵宾犬',
  '比熊犬',
  '柯基犬',
  '柴犬',
  '边境牧羊犬',
  '哈士奇',
  '博美犬',
  '萨摩耶',
  '杜宾犬',
  '罗威纳犬',
  customBreedOption,
];

List<String> breedOptionsFor(PetSpecies species) => switch (species) {
  PetSpecies.cat => catBreedOptions,
  PetSpecies.dog => dogBreedOptions,
  PetSpecies.other => const [customBreedOption],
};
