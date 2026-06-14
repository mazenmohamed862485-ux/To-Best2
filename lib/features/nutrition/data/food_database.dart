import '../../models/app_models.dart';

class FoodDatabase {
  static const List<FoodItem> all = [
    // ── Protein sources ────────────────────────
    FoodItem(name: 'صدر دجاج مسلوق', nameEn: 'Boiled Chicken Breast', cals: 165, p: 31, c: 0, f: 3.6, category: 'بروتين'),
    FoodItem(name: 'بيضة كاملة', nameEn: 'Whole Egg', cals: 155, p: 13, c: 1.1, f: 11, category: 'بروتين'),
    FoodItem(name: 'بياض بيض', nameEn: 'Egg White', cals: 52, p: 11, c: 0.7, f: 0.2, category: 'بروتين'),
    FoodItem(name: 'لحم بقر مفروم (90%)', nameEn: 'Ground Beef (90%)', cals: 176, p: 26, c: 0, f: 7.4, category: 'بروتين'),
    FoodItem(name: 'تونة بالماء', nameEn: 'Tuna in Water', cals: 116, p: 25.5, c: 0, f: 1, category: 'بروتين'),
    FoodItem(name: 'سمك سلمون', nameEn: 'Salmon', cals: 208, p: 20, c: 0, f: 13, category: 'بروتين'),
    FoodItem(name: 'جبن قريش', nameEn: 'Cottage Cheese', cals: 98, p: 11, c: 3.4, f: 4.3, category: 'بروتين'),
    FoodItem(name: 'زبادي يوناني (0%)', nameEn: 'Greek Yogurt 0%', cals: 59, p: 10, c: 3.6, f: 0.4, category: 'بروتين'),
    FoodItem(name: 'جبنة شيدر', nameEn: 'Cheddar Cheese', cals: 403, p: 25, c: 1.3, f: 33, category: 'بروتين'),
    FoodItem(name: 'لحم مفروم ديك رومي', nameEn: 'Ground Turkey', cals: 149, p: 21, c: 0, f: 7, category: 'بروتين'),
    FoodItem(name: 'أسماك سردين', nameEn: 'Sardines', cals: 208, p: 25, c: 0, f: 11, category: 'بروتين'),
    FoodItem(name: 'مسحوق بروتين واي', nameEn: 'Whey Protein Powder', cals: 380, p: 80, c: 6, f: 5, category: 'مكملات'),
    FoodItem(name: 'جمبري مسلوق', nameEn: 'Boiled Shrimp', cals: 99, p: 24, c: 0, f: 0.3, category: 'بروتين'),

    // ── Carbs ──────────────────────────────────
    FoodItem(name: 'أرز أبيض مطبوخ', nameEn: 'Cooked White Rice', cals: 130, p: 2.7, c: 28, f: 0.3, category: 'كربوهيدرات'),
    FoodItem(name: 'أرز بني مطبوخ', nameEn: 'Cooked Brown Rice', cals: 111, p: 2.6, c: 23, f: 0.9, category: 'كربوهيدرات'),
    FoodItem(name: 'شوفان', nameEn: 'Oats (raw)', cals: 389, p: 17, c: 66, f: 7, fiber: 10.6, category: 'كربوهيدرات'),
    FoodItem(name: 'خبز توست أبيض', nameEn: 'White Toast Bread', cals: 265, p: 9, c: 49, f: 3.2, category: 'كربوهيدرات'),
    FoodItem(name: 'خبز توست أسمر', nameEn: 'Whole Wheat Bread', cals: 247, p: 13, c: 41, f: 4.2, fiber: 6.9, category: 'كربوهيدرات'),
    FoodItem(name: 'بطاطا حلوة مسلوقة', nameEn: 'Boiled Sweet Potato', cals: 86, p: 1.6, c: 20, f: 0.1, fiber: 3, category: 'كربوهيدرات'),
    FoodItem(name: 'بطاطا مسلوقة', nameEn: 'Boiled Potato', cals: 77, p: 2, c: 17, f: 0.1, fiber: 1.8, category: 'كربوهيدرات'),
    FoodItem(name: 'عدس مطبوخ', nameEn: 'Cooked Lentils', cals: 116, p: 9, c: 20, f: 0.4, fiber: 7.9, category: 'كربوهيدرات', isVeg: true),
    FoodItem(name: 'معكرونة مطبوخة', nameEn: 'Cooked Pasta', cals: 131, p: 5, c: 25, f: 1.1, category: 'كربوهيدرات'),
    FoodItem(name: 'خبز عربي كامل القمح', nameEn: 'Whole Wheat Pita', cals: 247, p: 9, c: 46, f: 2, fiber: 6, category: 'كربوهيدرات'),
    FoodItem(name: 'كينوا مطبوخة', nameEn: 'Cooked Quinoa', cals: 120, p: 4.4, c: 21, f: 1.9, fiber: 2.8, category: 'كربوهيدرات', isVeg: true),
    FoodItem(name: 'حمص مسلوق', nameEn: 'Cooked Chickpeas', cals: 164, p: 8.9, c: 27, f: 2.6, fiber: 7.6, category: 'كربوهيدرات', isVeg: true),

    // ── Fats ───────────────────────────────────
    FoodItem(name: 'زيت زيتون', nameEn: 'Olive Oil', cals: 884, p: 0, c: 0, f: 100, category: 'دهون'),
    FoodItem(name: 'زيت جوز الهند', nameEn: 'Coconut Oil', cals: 862, p: 0, c: 0, f: 100, category: 'دهون'),
    FoodItem(name: 'لوز', nameEn: 'Almonds', cals: 579, p: 21, c: 22, f: 50, fiber: 12.5, category: 'دهون', isVeg: true),
    FoodItem(name: 'جوز', nameEn: 'Walnuts', cals: 654, p: 15, c: 14, f: 65, fiber: 6.7, category: 'دهون', isVeg: true),
    FoodItem(name: 'فول سوداني', nameEn: 'Peanuts', cals: 567, p: 26, c: 16, f: 49, fiber: 8.5, category: 'دهون', isVeg: true),
    FoodItem(name: 'زبدة فول سوداني', nameEn: 'Peanut Butter', cals: 588, p: 25, c: 20, f: 50, fiber: 6, category: 'دهون', isVeg: true),
    FoodItem(name: 'أفوكادو', nameEn: 'Avocado', cals: 160, p: 2, c: 9, f: 15, fiber: 6.7, category: 'دهون', isVeg: true),
    FoodItem(name: 'زبدة', nameEn: 'Butter', cals: 717, p: 0.9, c: 0.1, f: 81, category: 'دهون'),

    // ── Vegetables ────────────────────────────
    FoodItem(name: 'بروكلي', nameEn: 'Broccoli', cals: 34, p: 2.8, c: 7, f: 0.4, fiber: 2.6, category: 'خضروات', isVeg: true),
    FoodItem(name: 'سبانخ', nameEn: 'Spinach', cals: 23, p: 2.9, c: 3.6, f: 0.4, fiber: 2.2, category: 'خضروات', isVeg: true),
    FoodItem(name: 'طماطم', nameEn: 'Tomato', cals: 18, p: 0.9, c: 3.9, f: 0.2, fiber: 1.2, category: 'خضروات', isVeg: true),
    FoodItem(name: 'خيار', nameEn: 'Cucumber', cals: 15, p: 0.7, c: 3.6, f: 0.1, fiber: 0.5, category: 'خضروات', isVeg: true),
    FoodItem(name: 'جزر', nameEn: 'Carrot', cals: 41, p: 0.9, c: 10, f: 0.2, fiber: 2.8, category: 'خضروات', isVeg: true),
    FoodItem(name: 'فلفل رومي أخضر', nameEn: 'Green Bell Pepper', cals: 31, p: 1, c: 6, f: 0.3, fiber: 2.1, category: 'خضروات', isVeg: true),
    FoodItem(name: 'كوسة', nameEn: 'Zucchini', cals: 17, p: 1.2, c: 3.1, f: 0.3, fiber: 1, category: 'خضروات', isVeg: true),
    FoodItem(name: 'خس', nameEn: 'Lettuce', cals: 15, p: 1.4, c: 2.9, f: 0.2, fiber: 1.3, category: 'خضروات', isVeg: true),
    FoodItem(name: 'بصل', nameEn: 'Onion', cals: 40, p: 1.1, c: 9.3, f: 0.1, fiber: 1.7, category: 'خضروات', isVeg: true),
    FoodItem(name: 'ثوم', nameEn: 'Garlic', cals: 149, p: 6.4, c: 33, f: 0.5, fiber: 2.1, category: 'خضروات', isVeg: true),

    // ── Fruits ────────────────────────────────
    FoodItem(name: 'تفاح', nameEn: 'Apple', cals: 52, p: 0.3, c: 14, f: 0.2, fiber: 2.4, category: 'فواكه', isVeg: true),
    FoodItem(name: 'موز', nameEn: 'Banana', cals: 89, p: 1.1, c: 23, f: 0.3, fiber: 2.6, category: 'فواكه', isVeg: true),
    FoodItem(name: 'برتقال', nameEn: 'Orange', cals: 47, p: 0.9, c: 12, f: 0.1, fiber: 2.4, category: 'فواكه', isVeg: true),
    FoodItem(name: 'توت أزرق', nameEn: 'Blueberries', cals: 57, p: 0.7, c: 14, f: 0.3, fiber: 2.4, category: 'فواكه', isVeg: true),
    FoodItem(name: 'فراولة', nameEn: 'Strawberries', cals: 32, p: 0.7, c: 7.7, f: 0.3, fiber: 2, category: 'فواكه', isVeg: true),
    FoodItem(name: 'عنب', nameEn: 'Grapes', cals: 69, p: 0.7, c: 18, f: 0.2, fiber: 0.9, category: 'فواكه', isVeg: true),
    FoodItem(name: 'بطيخ', nameEn: 'Watermelon', cals: 30, p: 0.6, c: 7.6, f: 0.2, fiber: 0.4, category: 'فواكه', isVeg: true),
    FoodItem(name: 'تمر', nameEn: 'Dates', cals: 277, p: 1.8, c: 75, f: 0.2, fiber: 6.7, category: 'فواكه', isVeg: true),

    // ── Dairy ─────────────────────────────────
    FoodItem(name: 'حليب كامل الدسم', nameEn: 'Whole Milk', cals: 61, p: 3.2, c: 4.8, f: 3.3, category: 'ألبان'),
    FoodItem(name: 'حليب خالي الدسم', nameEn: 'Skim Milk', cals: 34, p: 3.4, c: 5, f: 0.1, category: 'ألبان'),
    FoodItem(name: 'زبادي عادي', nameEn: 'Plain Yogurt', cals: 61, p: 3.5, c: 4.7, f: 3.3, category: 'ألبان'),
    FoodItem(name: 'جبنة موزاريلا', nameEn: 'Mozzarella', cals: 280, p: 28, c: 2.2, f: 17, category: 'ألبان'),

    // ── Supplements & extras ──────────────────
    FoodItem(name: 'عسل', nameEn: 'Honey', cals: 304, p: 0.3, c: 82, f: 0, category: 'أخرى', isVeg: true),
    FoodItem(name: 'زيت السمك (كبسولة)', nameEn: 'Fish Oil Capsule', cals: 14, p: 0, c: 0, f: 1.5, category: 'مكملات'),
    FoodItem(name: 'كرياتين', nameEn: 'Creatine', cals: 0, p: 0, c: 0, f: 0, category: 'مكملات'),
  ];
}
