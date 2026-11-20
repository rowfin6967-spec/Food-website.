PRAGMA foreign_keys = ON;

CREATE TABLE IF NOT EXISTS categories (
  id   INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL UNIQUE
);

-- Nutrition values are approximate, per 100 g
CREATE TABLE IF NOT EXISTS foods (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  name        TEXT NOT NULL UNIQUE,
  category_id INTEGER NOT NULL REFERENCES categories(id),
  description TEXT NOT NULL,
  calories    INTEGER NOT NULL,
  protein     REAL NOT NULL,
  carbs       REAL NOT NULL,
  fat         REAL NOT NULL,
  origin      TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS posts (
  id         INTEGER PRIMARY KEY AUTOINCREMENT,
  title      TEXT NOT NULL,
  author     TEXT NOT NULL,
  body       TEXT NOT NULL,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

INSERT OR IGNORE INTO categories (name) VALUES
  ('Fruit'), ('Vegetable'), ('Grain'), ('Protein'), ('Dairy');

INSERT OR IGNORE INTO foods (name, category_id, description, calories, protein, carbs, fat, origin) VALUES
  ('Apple', (SELECT id FROM categories WHERE name = 'Fruit'),
   'Crisp and juicy, with fibre in the skin that slows sugar absorption.', 52, 0.3, 14, 0.2, 'Central Asia'),
  ('Banana', (SELECT id FROM categories WHERE name = 'Fruit'),
   'A quick energy snack that is rich in potassium.', 89, 1.1, 23, 0.3, 'Southeast Asia'),
  ('Broccoli', (SELECT id FROM categories WHERE name = 'Vegetable'),
   'Packed with vitamin C and vitamin K. Steam it briefly to keep its crunch.', 34, 2.8, 7, 0.4, 'Eastern Mediterranean'),
  ('Spinach', (SELECT id FROM categories WHERE name = 'Vegetable'),
   'Mild leafy green high in iron and folate. Good raw or wilted.', 23, 2.9, 3.6, 0.4, 'Persia'),
  ('Brown rice', (SELECT id FROM categories WHERE name = 'Grain'),
   'Whole grain rice with the bran left on, cooked. Nutty and filling.', 112, 2.3, 23, 0.8, 'Asia'),
  ('Salmon', (SELECT id FROM categories WHERE name = 'Protein'),
   'Oily fish that is a leading source of omega-3 fats, cooked.', 206, 22, 0, 12, 'North Atlantic and Pacific'),
  ('Eggs', (SELECT id FROM categories WHERE name = 'Protein'),
   'Boiled eggs: complete protein, affordable and endlessly versatile.', 155, 13, 1.1, 11, 'Worldwide'),
  ('Greek yogurt', (SELECT id FROM categories WHERE name = 'Dairy'),
   'Strained plain yogurt that is thick, tangy and high in protein.', 97, 9, 3.9, 5, 'Eastern Mediterranean');

-- Seed blog posts only when the table is empty
INSERT INTO posts (title, author, body)
SELECT title, author, body FROM (
  SELECT 'Why a one-pot dinner beats takeaway' AS title, 'Maya Ortiz' AS author,
         'Some weeknights ask for nothing more than a single pot and thirty minutes. Start with onions and garlic in olive oil, add a tin of tomatoes, a handful of lentils and enough stock to cover them. Simmer until soft, then finish with spinach and a squeeze of lemon.

The result is cheaper than delivery, higher in fibre and leaves one pan to wash. Make a double batch: it tastes better on the second day.' AS body
  UNION ALL
  SELECT 'A beginner guide to reading nutrition labels', 'Daniel Okafor',
         'Ignore the front of the pack and turn it over. Check the serving size first, because every number below it is based on that amount. Then look at added sugar, sodium and fibre.

A useful rule of thumb: if the ingredient list is short and you recognise every item, the food is probably close to its natural form.'
) WHERE NOT EXISTS (SELECT 1 FROM posts);
