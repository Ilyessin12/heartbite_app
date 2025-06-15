class SchemaStatements {
  static const String pragmaForeignKeysOn = 'PRAGMA foreign_keys = ON;';

  static const String createUsersTable = '''
CREATE TABLE users(
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    full_name TEXT NOT NULL,
    username TEXT UNIQUE NOT NULL,
    email TEXT UNIQUE NOT NULL,
    phone TEXT,
    password_hash TEXT NOT NULL,
    profile_picture TEXT,
    cover_picture TEXT,
    bio TEXT,
    is_active INTEGER DEFAULT 1,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
''';

  static const String createUserFollowsTable = '''
CREATE TABLE user_follows(
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    follower_id INTEGER NOT NULL,
    following_id INTEGER NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY(follower_id) REFERENCES users(id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY(following_id) REFERENCES users(id) ON DELETE CASCADE ON UPDATE CASCADE,
    UNIQUE(follower_id, following_id)
);
''';

  static const String createDietProgramsTable = '''
CREATE TABLE diet_programs(
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT UNIQUE NOT NULL,
    description TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
''';

  static const String createAllergensTable = '''
CREATE TABLE allergens(
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT UNIQUE NOT NULL,
    description TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
''';

  static const String createEquipmentTable = '''
CREATE TABLE equipment(
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT UNIQUE NOT NULL,
    description TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
''';

  static const String createCategoriesTable = '''
CREATE TABLE categories(
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT UNIQUE NOT NULL,
    description TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
''';

  static const String createIngredientsTable = '''
CREATE TABLE ingredients(
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT UNIQUE NOT NULL,
    unit TEXT,
    category TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
''';

  static const String createUserAllergensTable = '''
CREATE TABLE user_allergens(
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    allergen_id INTEGER NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY(allergen_id) REFERENCES allergens(id) ON DELETE CASCADE ON UPDATE CASCADE,
    UNIQUE(user_id, allergen_id)
);
''';

  static const String createUserDietProgramsTable = '''
CREATE TABLE user_diet_programs(
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    diet_program_id INTEGER NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY(diet_program_id) REFERENCES diet_programs(id) ON DELETE CASCADE ON UPDATE CASCADE,
    UNIQUE(user_id, diet_program_id)
);
''';

  static const String createUserMissingEquipmentTable = '''
CREATE TABLE user_missing_equipment(
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    equipment_id INTEGER NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY(equipment_id) REFERENCES equipment(id) ON DELETE CASCADE ON UPDATE CASCADE,
    UNIQUE(user_id, equipment_id)
);
''';

  static const String createIngredientAllergensTable = '''
CREATE TABLE ingredient_allergens(
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    ingredient_id INTEGER NOT NULL,
    allergen_id INTEGER NOT NULL,
    FOREIGN KEY(ingredient_id) REFERENCES ingredients(id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY(allergen_id) REFERENCES allergens(id) ON DELETE CASCADE ON UPDATE CASCADE,
    UNIQUE(ingredient_id, allergen_id)
);
''';

  static const String createRecipesTable = '''
CREATE TABLE recipes(
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    title TEXT NOT NULL,
    description TEXT,
    image_url TEXT,
    calories INTEGER,
    servings INTEGER NOT NULL DEFAULT 1,
    cooking_time_minutes INTEGER NOT NULL,
    difficulty_level TEXT DEFAULT 'medium' CHECK(difficulty_level IN ('easy', 'medium', 'hard')),
    is_published INTEGER DEFAULT 1,
    rating REAL DEFAULT 0.0,
    review_count INTEGER DEFAULT 0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE ON UPDATE CASCADE
);
''';

  static const String createRecipeCategoriesTable = '''
CREATE TABLE recipe_categories(
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    recipe_id INTEGER NOT NULL,
    category_id INTEGER NOT NULL,
    FOREIGN KEY(recipe_id) REFERENCES recipes(id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY(category_id) REFERENCES categories(id) ON DELETE CASCADE ON UPDATE CASCADE,
    UNIQUE(recipe_id, category_id)
);
''';

  static const String createRecipeDietProgramsTable = '''
CREATE TABLE recipe_diet_programs(
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    recipe_id INTEGER NOT NULL,
    diet_program_id INTEGER NOT NULL,
    FOREIGN KEY(recipe_id) REFERENCES recipes(id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY(diet_program_id) REFERENCES diet_programs(id) ON DELETE CASCADE ON UPDATE CASCADE,
    UNIQUE(recipe_id, diet_program_id)
);
''';

  static const String createRecipeIngredientsTable = '''
CREATE TABLE recipe_ingredients(
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    recipe_id INTEGER NOT NULL,
    ingredient_id INTEGER NOT NULL,
    quantity REAL NOT NULL,
    unit TEXT,
    notes TEXT,
    order_index INTEGER DEFAULT 0,
    FOREIGN KEY(recipe_id) REFERENCES recipes(id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY(ingredient_id) REFERENCES ingredients(id) ON DELETE RESTRICT ON UPDATE CASCADE
);
''';

  static const String createRecipeInstructionsTable = '''
CREATE TABLE recipe_instructions(
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    recipe_id INTEGER NOT NULL,
    step_number INTEGER NOT NULL,
    instruction TEXT NOT NULL,
    image_url TEXT,
    estimated_time_minutes INTEGER,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY(recipe_id) REFERENCES recipes(id) ON DELETE CASCADE ON UPDATE CASCADE,
    UNIQUE(recipe_id, step_number)
);
''';

  static const String createRecipeEquipmentTable = '''
CREATE TABLE recipe_equipment(
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    recipe_id INTEGER NOT NULL,
    equipment_id INTEGER NOT NULL,
    is_required INTEGER DEFAULT 1,
    notes TEXT,
    FOREIGN KEY(recipe_id) REFERENCES recipes(id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY(equipment_id) REFERENCES equipment(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    UNIQUE(recipe_id, equipment_id)
);
''';

  static const String createRecipeGalleryImagesTable = '''
CREATE TABLE recipe_gallery_images(
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    recipe_id INTEGER NOT NULL,
    image_url TEXT NOT NULL,
    caption TEXT,
    order_index INTEGER DEFAULT 0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY(recipe_id) REFERENCES recipes(id) ON DELETE CASCADE ON UPDATE CASCADE
);
''';

  static const String createRecipeLikesTable = '''
CREATE TABLE recipe_likes(
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    recipe_id INTEGER NOT NULL,
    user_id INTEGER NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY(recipe_id) REFERENCES recipes(id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE ON UPDATE CASCADE,
    UNIQUE(recipe_id, user_id)
);
''';

  static const String createBookmarkFoldersTable = '''
CREATE TABLE bookmark_folders(
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    name TEXT NOT NULL,
    description TEXT,
    is_default INTEGER DEFAULT 0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE ON UPDATE CASCADE,
    UNIQUE(user_id, name)
);
''';

  static const String createRecipeBookmarksTable = '''
CREATE TABLE recipe_bookmarks(
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    recipe_id INTEGER NOT NULL,
    user_id INTEGER NOT NULL,
    folder_id INTEGER NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY(recipe_id) REFERENCES recipes(id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY(folder_id) REFERENCES bookmark_folders(id) ON DELETE CASCADE ON UPDATE CASCADE,
    UNIQUE(recipe_id, user_id, folder_id)
);
''';

  static const String createRecipeCommentsTable = '''
CREATE TABLE recipe_comments(
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    recipe_id INTEGER NOT NULL,
    user_id INTEGER NOT NULL,
    parent_comment_id INTEGER,
    comment TEXT NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY(recipe_id) REFERENCES recipes(id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY(parent_comment_id) REFERENCES recipe_comments(id) ON DELETE CASCADE ON UPDATE CASCADE
);
''';

  static const String createCommentLikesTable = '''
CREATE TABLE comment_likes(
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    comment_id INTEGER NOT NULL,
    user_id INTEGER NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY(comment_id) REFERENCES recipe_comments(id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE ON UPDATE CASCADE,
    UNIQUE(comment_id, user_id)
);
''';

  static const String createRecipeRatingsTable = '''
CREATE TABLE recipe_ratings(
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    recipe_id INTEGER NOT NULL,
    user_id INTEGER NOT NULL,
    rating_value INTEGER NOT NULL CHECK(rating_value >= 1 AND rating_value <= 5),
    review_text TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY(recipe_id) REFERENCES recipes(id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE ON UPDATE CASCADE,
    UNIQUE(recipe_id, user_id)
);
''';

  static const String createNotificationsTable = '''
CREATE TABLE notifications(
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    actor_id INTEGER NOT NULL,
    type TEXT NOT NULL CHECK(type IN ('follow', 'like_recipe', 'comment', 'like_comment', 'reply', 'new_recipe', 'rating')),
    target_id INTEGER,
    target_type TEXT,
    message TEXT,
    is_read INTEGER DEFAULT 0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY(actor_id) REFERENCES users(id) ON DELETE CASCADE ON UPDATE CASCADE
);
''';

  // Indexes
  static const String createIdxRecipesCookingTime = 'CREATE INDEX idx_recipes_cooking_time ON recipes(cooking_time_minutes);';
  static const String createIdxRecipesCreatedAt = 'CREATE INDEX idx_recipes_created_at ON recipes(created_at);';
  static const String createIdxRecipesTitlePublished = 'CREATE INDEX idx_recipes_title_published ON recipes(title, is_published);';
  static const String createIdxRecipesUserCreated = 'CREATE INDEX idx_recipes_user_created ON recipes(user_id, created_at);';
  static const String createIdxRecipeBookmarksUserFolder = 'CREATE INDEX idx_recipe_bookmarks_user_folder ON recipe_bookmarks(user_id, folder_id);';
  static const String createIdxRecipeCommentsRecipeCreated = 'CREATE INDEX idx_recipe_comments_recipe_created ON recipe_comments(recipe_id, created_at);';
  static const String createIdxRecipeCommentsParent = 'CREATE INDEX idx_recipe_comments_parent ON recipe_comments(parent_comment_id);';
  static const String createIdxUserFollowsFollowingFollower = 'CREATE INDEX idx_user_follows_following_follower ON user_follows(following_id, follower_id);';
  static const String createIdxNotificationsUserReadCreated = 'CREATE INDEX idx_notifications_user_read_created ON notifications(user_id, is_read, created_at);';
  static const String createIdxRecipeGalleryRecipeId = 'CREATE INDEX idx_recipe_gallery_recipe_id ON recipe_gallery_images(recipe_id, order_index);';
  static const String createIdxRecipeRatingsRecipeUser = 'CREATE INDEX idx_recipe_ratings_recipe_user ON recipe_ratings(recipe_id, user_id);';

  static List<String> get allSchemaStatements => [
        createUsersTable,
        createUserFollowsTable,
        createDietProgramsTable,
        createAllergensTable,
        createEquipmentTable,
        createCategoriesTable,
        createIngredientsTable,
        createUserAllergensTable,
        createUserDietProgramsTable,
        createUserMissingEquipmentTable,
        createIngredientAllergensTable,
        createRecipesTable,
        createRecipeCategoriesTable,
        createRecipeDietProgramsTable,
        createRecipeIngredientsTable,
        createRecipeInstructionsTable,
        createRecipeEquipmentTable,
        createRecipeGalleryImagesTable,
        createRecipeLikesTable,
        createBookmarkFoldersTable,
        createRecipeBookmarksTable,
        createRecipeCommentsTable,
        createCommentLikesTable,
        createRecipeRatingsTable,
        createNotificationsTable,
        createIdxRecipesCookingTime,
        createIdxRecipesCreatedAt,
        createIdxRecipesTitlePublished,
        createIdxRecipesUserCreated,
        createIdxRecipeBookmarksUserFolder,
        createIdxRecipeCommentsRecipeCreated,
        createIdxRecipeCommentsParent,
        createIdxUserFollowsFollowingFollower,
        createIdxNotificationsUserReadCreated,
        createIdxRecipeGalleryRecipeId,
        createIdxRecipeRatingsRecipeUser,
      ];
}